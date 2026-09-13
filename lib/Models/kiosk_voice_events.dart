// ============================================================
// Kiosk Voice WebSocket — typed message models
// Source: websocket-message-catalog.md
// ============================================================
//
// One class per message `type`, plus a `KioskVoiceEvent.fromJson`
// dispatcher that reads the `type` field and returns the matching
// concrete class. Unknown/undocumented types fall back to
// `UnknownVoiceEvent` rather than throwing, since the catalog itself
// says it "may not be exhaustive."

// ------------------------------------------------------------
// Base type
// ------------------------------------------------------------

abstract class KioskVoiceEvent {
  final String type;
  final double? ts;

  KioskVoiceEvent({required this.type, this.ts});

  /// Dispatches on `json['type']` to the matching concrete event class.
  factory KioskVoiceEvent.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? '').toString();
    switch (type) {
      case 'ready':
        return ReadyEvent.fromJson(json);
      case 'triage_started':
        return TriageStartedEvent.fromJson(json);
      case 'agent_speaking':
        return AgentSpeakingEvent.fromJson(json);
      case 'agent_audio_chunk':
        return AgentAudioChunkEvent.fromJson(json);
      case 'agent_done_speaking':
        return AgentDoneSpeakingEvent.fromJson(json);
      case 'user_speech_started':
        return UserSpeechStartedEvent.fromJson(json);
      case 'partial_transcript':
        return PartialTranscriptEvent.fromJson(json);
      case 'category_identified':
        return CategoryIdentifiedEvent.fromJson(json);
      case 'consultation_started':
        return ConsultationStartedEvent.fromJson(json);
      case 'silence_nudge':
        return SilenceNudgeEvent.fromJson(json);
      case 'consultation_ended':
        return ConsultationEndedEvent.fromJson(json);
      case 'result_ready':
        return ResultReadyEvent.fromJson(json);
      case 'ended':
        return EndedEvent.fromJson(json);
      default:
        return UnknownVoiceEvent.fromJson(json);
    }
  }
}


// ------------------------------------------------------------
// Server -> Client events
// ------------------------------------------------------------

class ReadyEvent extends KioskVoiceEvent {
  final String? sessionId;
  final String? phase;
  final String? language;
  final String? voiceMode;

  ReadyEvent({
    this.sessionId,
    this.phase,
    this.language,
    this.voiceMode,
    super.ts,
  }) : super(type: 'ready');

  factory ReadyEvent.fromJson(Map<String, dynamic> json) {
    return ReadyEvent(
      sessionId: json['session_id'],
      phase: json['phase'],
      language: json['language'],
      voiceMode: json['voice_mode'],
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'session_id': sessionId,
    'phase': phase,
    'language': language,
    'voice_mode': voiceMode,
    'ts': ts,
  };

  @override
  String toString() =>
      'ReadyEvent(sessionId: $sessionId, phase: $phase, language: $language)';
}


class TriageStartedEvent extends KioskVoiceEvent {
  final String? sessionId;
  final String? language;

  TriageStartedEvent({
    this.sessionId,
    this.language,
    super.ts,
  }) : super(type: 'triage_started');

  factory TriageStartedEvent.fromJson(Map<String, dynamic> json) {
    return TriageStartedEvent(
      sessionId: json['session_id'],
      language: json['language'],
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'session_id': sessionId,
    'language': language,
    'ts': ts,
  };

  @override
  String toString() =>
      'TriageStartedEvent(sessionId: $sessionId, language: $language)';
}


class AgentSpeakingEvent extends KioskVoiceEvent {
  final String? question; // incremental — grows across messages within `turn`
  final int? turn;

  AgentSpeakingEvent({
    this.question,
    this.turn,
    super.ts,
  }) : super(type: 'agent_speaking');

  factory AgentSpeakingEvent.fromJson(Map<String, dynamic> json) {
    return AgentSpeakingEvent(
      question: json['question'],
      turn: json['turn'],
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'question': question,
    'turn': turn,
    'ts': ts,
  };

  @override
  String toString() => 'AgentSpeakingEvent(turn: $turn, question: $question)';
}


class AgentAudioChunkEvent extends KioskVoiceEvent {
  final String? audioB64; // base64-encoded PCM, 24kHz per mime
  final String? mime;

  AgentAudioChunkEvent({
    this.audioB64,
    this.mime,
    super.ts,
  }) : super(type: 'agent_audio_chunk');

  factory AgentAudioChunkEvent.fromJson(Map<String, dynamic> json) {
    return AgentAudioChunkEvent(
      audioB64: json['audio_b64'],
      mime: json['mime'],
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'audio_b64': audioB64,
    'mime': mime,
    'ts': ts,
  };

  // Deliberately omits audioB64 from toString to avoid dumping raw
  // base64 audio payloads into logs.
  @override
  String toString() =>
      'AgentAudioChunkEvent(mime: $mime, audioB64Length: ${audioB64?.length})';
}


class AgentDoneSpeakingEvent extends KioskVoiceEvent {
  final int? turn;

  AgentDoneSpeakingEvent({
    this.turn,
    super.ts,
  }) : super(type: 'agent_done_speaking');

  factory AgentDoneSpeakingEvent.fromJson(Map<String, dynamic> json) {
    return AgentDoneSpeakingEvent(
      turn: json['turn'],
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'turn': turn,
    'ts': ts,
  };

  @override
  String toString() => 'AgentDoneSpeakingEvent(turn: $turn)';
}


class UserSpeechStartedEvent extends KioskVoiceEvent {
  UserSpeechStartedEvent({super.ts}) : super(type: 'user_speech_started');

  factory UserSpeechStartedEvent.fromJson(Map<String, dynamic> json) {
    return UserSpeechStartedEvent(
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'ts': ts,
  };

  @override
  String toString() => 'UserSpeechStartedEvent(ts: $ts)';
}


class PartialTranscriptEvent extends KioskVoiceEvent {
  final String? text; // incremental transcript text

  PartialTranscriptEvent({
    this.text,
    super.ts,
  }) : super(type: 'partial_transcript');

  factory PartialTranscriptEvent.fromJson(Map<String, dynamic> json) {
    return PartialTranscriptEvent(
      text: json['text'],
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'text': text,
    'ts': ts,
  };

  @override
  String toString() => 'PartialTranscriptEvent(text: $text)';
}


/// Nested `category` object as sent by `category_identified` — note this
/// shape (`{key, label}`) differs from `consultation_started.category`,
/// which is a bare string. See EventCategoryKey below for that one.
class EventCategory {
  final String? key;
  final String? label;

  EventCategory({this.key, this.label});

  factory EventCategory.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return EventCategory(
      key: json['key'],
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
  };

  @override
  String toString() => 'EventCategory(key: $key, label: $label)';
}


class CategoryIdentifiedEvent extends KioskVoiceEvent {
  final EventCategory? category;
  final String? confidence; // enum: high | medium | low

  CategoryIdentifiedEvent({
    this.category,
    this.confidence,
    super.ts,
  }) : super(type: 'category_identified');

  factory CategoryIdentifiedEvent.fromJson(Map<String, dynamic> json) {
    return CategoryIdentifiedEvent(
      category: json['category'] != null
          ? EventCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      confidence: json['confidence'],
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'category': category?.toJson(),
    'confidence': confidence,
    'ts': ts,
  };

  @override
  String toString() =>
      'CategoryIdentifiedEvent(category: $category, confidence: $confidence)';
}


class ConsultationStartedEvent extends KioskVoiceEvent {
  // NOTE: unlike CategoryIdentifiedEvent, the catalog documents this as a
  // bare string (the category key only, no label) — kept as String? here
  // rather than reusing EventCategory. Confirm with backend whether this
  // is intentional.
  final String? category;
  final int? startingTurn;

  ConsultationStartedEvent({
    this.category,
    this.startingTurn,
    super.ts,
  }) : super(type: 'consultation_started');

  factory ConsultationStartedEvent.fromJson(Map<String, dynamic> json) {
    return ConsultationStartedEvent(
      category: json['category']?.toString(),
      startingTurn: json['starting_turn'],
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'category': category,
    'starting_turn': startingTurn,
    'ts': ts,
  };

  @override
  String toString() =>
      'ConsultationStartedEvent(category: $category, startingTurn: $startingTurn)';
}


class SilenceNudgeEvent extends KioskVoiceEvent {
  SilenceNudgeEvent({super.ts}) : super(type: 'silence_nudge');

  factory SilenceNudgeEvent.fromJson(Map<String, dynamic> json) {
    return SilenceNudgeEvent(
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'ts': ts,
  };

  @override
  String toString() => 'SilenceNudgeEvent(ts: $ts)';
}


class ConsultationEndedEvent extends KioskVoiceEvent {
  ConsultationEndedEvent({super.ts}) : super(type: 'consultation_ended');

  factory ConsultationEndedEvent.fromJson(Map<String, dynamic> json) {
    return ConsultationEndedEvent(
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'ts': ts,
  };

  @override
  String toString() => 'ConsultationEndedEvent(ts: $ts)';
}


/// One entry in `result_ready.flags[]`.
class EventFlag {
  final String? flagType; // enum: NOTE | IMPORTANT
  final String? description;
  final String? raisedAt;

  EventFlag({this.flagType, this.description, this.raisedAt});

  factory EventFlag.fromJson(Map<String, dynamic> json) {
    return EventFlag(
      flagType: json['flag_type'],
      description: json['description'],
      raisedAt: json['raised_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'flag_type': flagType,
    'description': description,
    'raised_at': raisedAt,
  };

  @override
  String toString() => 'EventFlag(flagType: $flagType, description: $description)';
}


class ResultReadyEvent extends KioskVoiceEvent {
  final String? summary;
  final List<EventFlag> flags;

  ResultReadyEvent({
    this.summary,
    required this.flags,
    super.ts,
  }) : super(type: 'result_ready');

  factory ResultReadyEvent.fromJson(Map<String, dynamic> json) {
    return ResultReadyEvent(
      summary: json['summary'],
      flags: (json['flags'] as List<dynamic>? ?? [])
          .map((e) => EventFlag.fromJson(e as Map<String, dynamic>))
          .toList(),
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'summary': summary,
    'flags': flags.map((e) => e.toJson()).toList(),
    'ts': ts,
  };

  @override
  String toString() =>
      'ResultReadyEvent(summary: $summary, flagCount: ${flags.length})';
}


class EndedEvent extends KioskVoiceEvent {
  final String? sessionId;

  EndedEvent({
    this.sessionId,
    super.ts,
  }) : super(type: 'ended');

  factory EndedEvent.fromJson(Map<String, dynamic> json) {
    return EndedEvent(
      sessionId: json['session_id'],
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'session_id': sessionId,
    'ts': ts,
  };

  @override
  String toString() => 'EndedEvent(sessionId: $sessionId)';
}


/// Fallback for any `type` not in the catalog above — the catalog itself
/// notes it "may not be exhaustive" (errors, reconnects, etc. may exist
/// but are undocumented). Keeps the raw payload instead of throwing.
class UnknownVoiceEvent extends KioskVoiceEvent {
  final Map<String, dynamic> raw;

  UnknownVoiceEvent({
    required this.raw,
    super.ts,
  }) : super(type: (raw['type'] ?? 'unknown').toString());

  factory UnknownVoiceEvent.fromJson(Map<String, dynamic> json) {
    return UnknownVoiceEvent(
      raw: json,
      ts: (json['ts'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => raw;

  @override
  String toString() => 'UnknownVoiceEvent(type: $type, raw: $raw)';
}


// ------------------------------------------------------------
// Client -> Server messages
// ------------------------------------------------------------

/// {"type": "start"} — the only documented client message besides raw
/// binary PCM audio frames (which have no JSON model; sent as-is).
class StartMessage {
  final String type = 'start';

  StartMessage();

  Map<String, dynamic> toJson() => {'type': type};

  @override
  String toString() => 'StartMessage()';
}
