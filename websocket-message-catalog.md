# WebSocket Message Catalog — Triage/Consultation Session

Reference documentation for the real-time WebSocket protocol used during a patient checkin session (triage → consultation flow), reverse-engineered from captured traffic.

---

## Client → Server Messages

| `type` | Fields | Example |
|---|---|---|
| `start` | `type` | `{"type":"start"}` |
| *(binary)* | raw PCM audio bytes | Sent as binary audio frames (microphone input), no JSON wrapper |

---

## Server → Client Messages

| `type` | Fields | Description |
|---|---|---|
| `ready` | `type`, `session_id`, `phase`, `language`, `voice_mode`, `ts` | Session initialized and ready to receive audio |
| `triage_started` | `type`, `session_id`, `language`, `ts` | Triage phase begins |
| `agent_speaking` | `type`, `question`, `turn`, `ts` | Streamed partial text of the AI agent's speech (incremental — `question` grows across messages within the same `turn`) |
| `agent_audio_chunk` | `type`, `audio_b64`, `mime`, `ts` | Streamed audio of the agent's speech (base64-encoded PCM), paired with `agent_speaking` |
| `agent_done_speaking` | `type`, `turn`, `ts` | Marks the end of the agent's current speaking turn |
| `user_speech_started` | `type`, `ts` | Server detected the user started speaking (voice activity detection trigger) |
| `partial_transcript` | `type`, `text`, `ts` | Live speech-to-text transcript of the user's speech (incremental) |
| `category_identified` | `type`, `category {key, label}`, `confidence`, `ts` | AI classifies the case into a medical category |
| `consultation_started` | `type`, `category`, `starting_turn`, `ts` | Consultation phase begins after triage/categorization |
| `silence_nudge` | `type`, `ts` | Sent when the user is silent for a period (prompt/nudge trigger) |
| `consultation_ended` | `type`, `ts` | Consultation phase concludes |
| `result_ready` | `type`, `summary`, `flags[]`, `ts` | Final structured output — summary plus clinical/administrative flags |
| `ended` | `type`, `session_id`, `ts` | Session fully closed |

---

## Expanded Structures

### `ready`
```json
{
    "type": "ready",
    "session_id": "<uuid-string>",
    "phase": "<string, enum e.g. 'triage'>",
    "language": "<string, ISO 639-1 code>",
    "voice_mode": "<string, e.g. 'gemini_live'>",
    "ts": "<float, Unix timestamp>"
}
```

### `triage_started`
```json
{
    "type": "triage_started",
    "session_id": "<uuid-string>",
    "language": "<string, ISO 639-1 code>",
    "ts": "<float, Unix timestamp>"
}
```

### `agent_speaking`
```json
{
    "type": "agent_speaking",
    "question": "<string, partial/incremental text>",
    "turn": "<integer, turn index>",
    "ts": "<float, Unix timestamp>"
}
```

### `agent_audio_chunk`
```json
{
    "type": "agent_audio_chunk",
    "audio_b64": "<string, base64-encoded PCM audio chunk>",
    "mime": "<string, e.g. 'audio/pcm;rate=24000'>",
    "ts": "<float, Unix timestamp>"
}
```

### `agent_done_speaking`
```json
{
    "type": "agent_done_speaking",
    "turn": "<integer, turn index>",
    "ts": "<float, Unix timestamp>"
}
```

### `user_speech_started`
```json
{
    "type": "user_speech_started",
    "ts": "<float, Unix timestamp>"
}
```

### `partial_transcript`
```json
{
    "type": "partial_transcript",
    "text": "<string, incremental transcript text>",
    "ts": "<float, Unix timestamp>"
}
```

### `category_identified`
```json
{
    "type": "category_identified",
    "category": {
        "key": "<string, machine-readable category id>",
        "label": "<string, human-readable category name>"
    },
    "confidence": "<string, enum e.g. 'high' | 'medium' | 'low'>",
    "ts": "<float, Unix timestamp>"
}
```

### `consultation_started`
```json
{
    "type": "consultation_started",
    "category": "<string, category key>",
    "starting_turn": "<integer>",
    "ts": "<float, Unix timestamp>"
}
```

### `silence_nudge`
```json
{
    "type": "silence_nudge",
    "ts": "<float, Unix timestamp>"
}
```

### `consultation_ended`
```json
{
    "type": "consultation_ended",
    "ts": "<float, Unix timestamp>"
}
```

### `result_ready`
```json
{
    "type": "result_ready",
    "summary": "<string | null>",
    "flags": [
        {
            "flag_type": "<string, enum 'NOTE' | 'IMPORTANT'>",
            "description": "<string>",
            "raised_at": "<ISO 8601 datetime string>"
        }
    ],
    "ts": "<float, Unix timestamp>"
}
```

### `ended`
```json
{
    "type": "ended",
    "session_id": "<uuid-string>",
    "ts": "<float, Unix timestamp>"
}
```

---

## Observed Session Flow

```
Client: start
Server: ready
Server: triage_started
   ↔ [loop] Client sends PCM audio
        Server: agent_speaking (+ agent_audio_chunk, repeated within a turn) → agent_done_speaking
        Server: user_speech_started → partial_transcript (repeated)
Server: category_identified
Server: consultation_started
   ↔ [loop continues: agent_speaking / user speech / silence_nudge on inactivity]
Server: consultation_ended
Server: result_ready
Server: ended
```

**Key patterns:**
- The conversation is **turn-based**: each `turn` number groups one agent utterance (`agent_speaking` text chunks + `agent_audio_chunk` audio chunks, closed by `agent_done_speaking`), interleaved with user speech detection (`user_speech_started` + `partial_transcript`).
- The session moves through two phases — **triage** → **consultation** — gated by `category_identified` and `consultation_started`.
- The session ends with a flagged summary (`result_ready`) followed by formal closure (`ended`).

---

*This catalog reflects messages observed in a single captured session and may not be exhaustive. Additional message types (e.g., errors, reconnects, phase transitions back to triage) may exist and should be appended here as observed.*
