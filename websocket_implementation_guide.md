# Kiosk Voice WebSocket — Implementation Guide (Ideal Conditions)

## 0. Scope & Assumptions

This document covers **only** the real-time voice WebSocket portion of the kiosk flow — from the moment a patient session is created through to session closure. It assumes the rest of the system is already working: login, hospital/kiosk config fetch, PIN unlock, and `POST /session` (which returns the `session_id` this WebSocket connects against).

This pass targets **ideal conditions only** — a stable connection, correct audio hardware, no dropped frames. The following are explicitly **out of scope** for this version and called out again in Section 7:

- Reconnect/retry logic if the socket drops mid-session
- Handling of undocumented/error event types beyond a silent no-op
- Jitter-buffer tuning under poor network conditions
- Long-session file cleanup/rotation

(Mic gating is now in scope — see Section 2 — but is defined here as message-driven, not playback-driven. See the note in that section on the tradeoff this implies.)

Reference docs this builds on: `websocket-message-catalog.md` (event catalog) and `kiosk_session_timeline.md` (observed real-world timing).

---

## 1. Connection Lifecycle

Per the timeline, the WebSocket opens almost immediately after the session is created (roughly a 2-second gap observed). The intended sequence is:

1. `POST /session` returns `session_id`.
2. Open the WebSocket to `wss://.../api/v2/t/{slug}/session/{session_id}/voice?token={kiosk_token}`.
3. Subscribe to the incoming message stream **before** sending anything, so no early server messages are missed.
4. Send the client `start` message.
5. Wait for the server's `ready` event — this is the signal that the server is prepared to receive audio.
6. Only after `ready`, begin mic capture and start streaming audio out.
7. Continue running through the triage → consultation phases (interleaved `agent_speaking`/`agent_audio_chunk`/transcript/category events) until `result_ready` and then `ended`.
8. Close the socket on `ended`, then proceed to `GET /result`.

The key rule: **nothing audio-related happens before `ready`, and nothing should still be running after `ended`.**

---

## 2. Outbound Audio (Mic → Server)

- **Format:** 16kHz, mono, PCM 16-bit, raw bytes — sent as unwrapped binary WebSocket frames, no JSON envelope, no base64.
- **Start condition:** only after `ready` is received, not before.
- **Delivery:** stream chunks continuously as they're captured. Do not batch multiple chunks together before sending — this only adds latency for no benefit, since the server appears to be doing streaming ASR/VAD on the incoming bytes.
- **Stop condition (session end):** recording should stop once the consultation is clearly over — by `result_ready` at the latest, and definitely by `ended`.
- **Mic gating (turn-level, message-driven):**
  - Mic **stops** the moment `agent_speaking` is received.
  - Mic **starts** the moment `agent_done_speaking` is received.
  - This is a deliberate simplification: it gates strictly on the *message* boundary, not on actual playback completion. Since `agent_done_speaking` only means "no more chunks are coming for this turn" — not "the speaker has gone quiet" — there's a real chance the mic reopens slightly before the tail of the agent's audio has finished playing out loud, especially if there's any pre-buffering or network lag on the inbound audio (Section 3). In practice this window is likely small, and it trades a small residual echo risk for a much simpler implementation than gating on playback drain. Worth revisiting if echo turns out to be audible on real hardware.

---

## 3. Inbound Audio (Server → Speaker)

- **Format:** PCM, 24kHz confirmed via the documented mime string (`audio/pcm;rate=24000`). Bit depth, channel count, and byte order are **reasonable assumptions** (16-bit signed, mono, little-endian) but not explicitly documented anywhere in the catalog — worth confirming against a real captured chunk before trusting playback quality, since a wrong assumption here produces garbled/static audio rather than an obvious error.
- **Playback model:** chunks arrive incrementally within a single agent turn and must be treated as one continuous stream, not a sequence of discrete clips. Restarting a player against a growing file on every new chunk (rather than continuously feeding a single ongoing playback buffer) risks replaying already-heard audio — see Section 6a.
- **Buffering:** a small pre-buffer (roughly 100–200ms of audio) before starting playback smooths over minor arrival jitter between chunks. This doesn't need to be tuned precisely for the ideal-conditions pass, but the mechanism should exist.
- **Termination:** playback should be considered "done" only when the buffered audio has actually finished playing out loud — not simply when the last `agent_audio_chunk` was received. `agent_done_speaking` only means no more chunks are coming for that turn, not that the speaker has gone quiet.

---

## 4. Event → State Mapping

| Event | Expected state change |
|---|---|
| `ready` | Phase set to initial value (`triage`); begin mic capture |
| `triage_started` | Phase → "Triage" |
| `agent_speaking` | Update displayed agent text (incremental, grows per `turn`); **stop mic** |
| `agent_audio_chunk` | Decode + play; not a UI state change on its own |
| `agent_done_speaking` | No UI change required; **start mic** |
| `user_speech_started` | Transcript UI → "Listening..." |
| `partial_transcript` | Update displayed transcript text (incremental) |
| `category_identified` | Store category label/key for display |
| `consultation_started` | Phase → "Consultation" |
| `silence_nudge` | No required UI change (optional prompt if desired) |
| `consultation_ended` | Phase → "Concluded"; consultation is over, but playback may still be finishing |
| `result_ready` | Store result payload; stop mic capture |
| `ended` | Close socket; stop mic capture if not already stopped; hand off to `GET /result` |

---

## 5. Session Termination — Three Distinct Signals

The catalog documents three separate closing events, in this order, and each should trigger a different action rather than being treated interchangeably:

1. **`consultation_ended`** — the conversation content is over. No new agent turns will start.
2. **`result_ready`** — the structured summary/flags are available. This is the right point to stop the mic, since no further patient input is expected.
3. **`ended`** — the session is fully closed server-side. This is the point to close the socket and move to `GET /result`.

Only one of these should own "stop recording" as its responsibility (recommend `result_ready`) — having multiple events independently call stop is harmless but makes the intended trigger unclear when revisiting the code later.

---

## 6. Review Notes — Current Implementation

Going through the shared `KioskConsultationService` against the spec above:

**a. Playback restarts from the beginning of the file on every call.**
`_startContinuousPlayback` calls `startPlayer(fromURI: _persistentAudioFile.path, ...)` both on the initial call and again from `whenFinished` every time more buffered data arrives. The file is opened once, in append mode, and grows for the whole session. Starting playback `fromURI` typically begins reading from the start of the file — so each restart risks re-playing audio already heard, rather than continuing from where playback last left off. This is the most likely source of any "audio repeats itself" or "audio stutters oddly" symptom.

**b. The jitter buffer isn't actually feeding playback.**
Chunks are pushed into `_jitterBuffer`, and `_jitterBuffer.totalBytes` is used to decide *when* to start playback — but the audio that actually plays comes from `_persistentAudioFile`, not from `_jitterBuffer.readNext()`. That method is never called anywhere in the file. So the buffer functions only as a "have we received enough bytes yet" gate; it doesn't drain, and it doesn't do the buffering work its name implies.

**c. No mic gating currently exists — now a defined requirement.**
`_startRecording()` fires once on `ready` and runs continuously through to `result_ready`/`ended`, with nothing pausing capture while the agent is speaking. Per the updated Section 2 rule, this needs a stop call added on `agent_speaking` and a resume call added on `agent_done_speaking`. Note this means recording needs to support pause/resume (or an equivalent gate on whether captured chunks get sent), not just a single start/stop for the whole session as it's currently structured.

**d. Every inbound chunk is written to disk for the session's full duration.**
`_audioSink` writes every chunk as it arrives, and the file isn't trimmed or rotated — only deleted at `dispose()`. For a single ~2.5 minute session (per the timeline) this is unlikely to be a real problem, but it's worth noting the file grows unbounded for the life of the session, and disk I/O sits directly in the real-time playback path.

**e. Event dispatch is done twice.**
`KioskVoiceEvent.fromJson` already resolves each message to its concrete subtype (`ReadyEvent`, `AgentSpeakingEvent`, etc.). `_handleEvent`'s `switch (event.type)` + `as` casts re-does that dispatch via string matching on top of the already-typed object. Not incorrect, just redundant — a chain of `if (event is AgentSpeakingEvent) ...` would use the typing that already exists instead of re-deriving it.

**f. `_stopRecording()` is called from two different events.**
It's called on both `result_ready` and `ended`. Calling it twice is harmless (idempotent), but per Section 5, only one of these should be the "real" trigger — recommend consolidating to `result_ready` and treating the call in the `ended` branch as a safety net rather than the primary path.

---

## 7. Explicitly Out of Scope for This Pass

Restating from Section 0, now that the review above has surfaced where these would eventually plug in:

- **Reconnect/retry** — nothing here handles a dropped WebSocket; `onDone`/`onError` currently just update UI state and stop, with no attempt to resume the session.
- **Error/undocumented events** — the `default` case in `_handleEvent` silently does nothing, matching the catalog's own admission that it "may not be exhaustive." Fine for now; revisit once error event shapes are actually observed.
- **Jitter-buffer correctness under real network conditions** — the current buffer's role should be clarified (per 6b) before it's tuned for anything beyond ideal conditions.
- **Long-session file handling** — not a concern at ~2.5 minutes per session, but worth a note if session length assumptions ever change.
