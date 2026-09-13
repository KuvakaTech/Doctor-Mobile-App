import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A single message received over the kiosk voice WebSocket.
///
/// Per `websocket-message-catalog.md`, `type` is one of:
///   ready, triage_started, agent_speaking, agent_audio_chunk,
///   agent_done_speaking, user_speech_started, partial_transcript,
///   category_identified, consultation_started, silence_nudge,
///   consultation_ended, result_ready, ended
///
/// Kept generic (type + raw data) rather than one class per event type,
/// matching the pattern used for VoiceStreamMessage. Callers switch on
/// `type` and pull typed fields out of `data` as needed.
class KioskVoiceMessage {
  final String type;
  final Map<String, dynamic> data;

  KioskVoiceMessage({required this.type, required this.data});

  factory KioskVoiceMessage.fromJson(Map<String, dynamic> json) {
    return KioskVoiceMessage(
      type: (json['type'] ?? '').toString(),
      data: json,
    );
  }

  @override
  String toString() => 'KioskVoiceMessage(type: $type, data: $data)';
}

/// WS /api/v2/t/{slug}/session/{session_id}/voice?token=...
/// Wraps the raw WebSocketChannel with helpers matching the documented
/// kiosk protocol:
///
/// Backend Protocol (Client-Initiated):
///   1. Connect to WebSocket
///   2. Client sends: {"type": "start"}
///   3. Server responds: {"type": "ready", session_id, phase, language, voice_mode}
///   4. Client streams raw binary PCM audio chunks (16kHz, mono, 16-bit)
///   5. Server streams `agent_speaking` / `agent_audio_chunk` (24kHz PCM,
///      base64) / transcript / category / phase events, interleaved
///   6. Server sends `result_ready` then `ended` to close out the session
///
/// NOTE: the catalog does not document a client-sent "stop" message —
/// unlike the /consultation/voice-stream protocol above, the observed
/// session simply ends when the server sends `ended`, at which point the
/// caller should close() the channel. No `mime_type` is sent on `start`
/// either, since audio here is raw PCM, not AAC/WAV/opus.
///
/// Listen to `messages` for parsed server events.
class KioskVoiceConnection {
  final WebSocketChannel _channel;
  final Stream<KioskVoiceMessage> messages;

  KioskVoiceConnection._(this._channel, this.messages);

  factory KioskVoiceConnection.connect({
    // host only, no scheme, e.g. "med-history-agent.decrackle.io"
    required String host,
    required String slug,
    required String sessionId,
    required String kioskToken,
    bool secure = true,
  }) {
    final scheme = secure ? "wss" : "ws";
    final uri = Uri.parse(
      "$scheme://$host/api/v2/t/$slug/session/$sessionId/voice?token=$kioskToken",
    );
    final channel = WebSocketChannel.connect(uri);

    final messages = channel.stream
        .where((event) => event is String) // JSON text frames only
        .map((event) {
          return KioskVoiceMessage.fromJson(
            jsonDecode(event as String) as Map<String, dynamic>,
          );
        });

    return KioskVoiceConnection._(channel, messages);
  }

  /// Send start message to initiate audio streaming.
  /// Must be called FIRST after WebSocket connection, BEFORE any audio chunks.
  /// Server will respond with {"type":"ready", ...} when it's ready.
  void start() {
    final message = jsonEncode({"type": "start"});
    _channel.sink.add(message);
  }

  /// Send a chunk of raw binary PCM audio data (16kHz, mono, 16-bit),
  /// as captured from the mic — no JSON wrapper, per the catalog.
  void sendAudioChunk(List<int> bytes) {
    _channel.sink.add(bytes);
  }

  Future<void> close() {
    return _channel.sink.close();
  }
}
