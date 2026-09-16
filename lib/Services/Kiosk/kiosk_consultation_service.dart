import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:flutter_sound/flutter_sound.dart';

import '../../Models/kiosk_voice_events.dart';
import '../../Models/kiosk_voice_socket.dart';
import 'kiosk_service.dart';

class KioskConsultationState {
  final String currentPhase;
  final String agentText;
  final String userTranscript;
  final String? categoryLabel;
  final ResultReadyEvent? resultReadyEvent;
  final bool isRecording;
  final double currentAmplitude;

  const KioskConsultationState({
    this.currentPhase = "Connecting...",
    this.agentText = "Waiting for agent...",
    this.userTranscript = "",
    this.categoryLabel,
    this.resultReadyEvent,
    this.isRecording = false,
    this.currentAmplitude = -60.0,
  });

  KioskConsultationState copyWith({
    String? currentPhase,
    String? agentText,
    String? userTranscript,
    String? categoryLabel,
    ResultReadyEvent? resultReadyEvent,
    bool? isRecording,
    double? currentAmplitude,
  }) {
    return KioskConsultationState(
      currentPhase: currentPhase ?? this.currentPhase,
      agentText: agentText ?? this.agentText,
      userTranscript: userTranscript ?? this.userTranscript,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      resultReadyEvent: resultReadyEvent ?? this.resultReadyEvent,
      isRecording: isRecording ?? this.isRecording,
      currentAmplitude: currentAmplitude ?? this.currentAmplitude,
    );
  }
}

class KioskConsultationParams {
  final String slug;
  final String sessionId;
  final String kioskToken;

  const KioskConsultationParams({
    required this.slug,
    required this.sessionId,
    required this.kioskToken,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KioskConsultationParams &&
          runtimeType == other.runtimeType &&
          slug == other.slug &&
          sessionId == other.sessionId &&
          kioskToken == other.kioskToken;

  @override
  int get hashCode => slug.hashCode ^ sessionId.hashCode ^ kioskToken.hashCode;
}

class JitterBuffer {
  final List<Uint8List> _queue = [];
  int _totalBytes = 0;

  void add(Uint8List chunk) {
    _queue.add(chunk);
    _totalBytes += chunk.length;
  }

  bool get isEmpty => _queue.isEmpty;
  int get totalBytes => _totalBytes;

  Uint8List? readNext() {
    if (_queue.isEmpty) return null;
    final chunk = _queue.removeAt(0);
    _totalBytes -= chunk.length;
    return chunk;
  }

  void clear() {
    _queue.clear();
    _totalBytes = 0;
  }
}

class KioskConsultationService extends StateNotifier<KioskConsultationState> {
  final KioskConsultationParams params;
  KioskVoiceConnection? _connection;
  StreamSubscription<KioskVoiceMessage>? _sub;
  final AudioRecorder _recorder = AudioRecorder();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  bool _playerIsOpen = false;
  bool _isPlayerStreaming = false;
  bool _isStartingStream = false;
  bool _isTurnBuffering = false;
  bool _sessionActive = true;

  final JitterBuffer _jitterBuffer = JitterBuffer();

  StreamSubscription<Uint8List>? _audioStreamSub;
  StreamSubscription<Amplitude>? _amplitudeSub;
  bool _isRecordingActive = false;
  bool _isMicGated = false;

  final _recordConfig = const RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
  );

  // Pre-buffer threshold: ~150ms at 24kHz mono 16-bit (24000 * 2 * 0.15 = 7200 bytes)
  static const int _preBufferThreshold = 7200;

  KioskConsultationService(this.params) : super(const KioskConsultationState()) {
    _initAudioPipeline();
    connectWebSocket();
  }

  Future<void> _initAudioPipeline() async {
    try {
      await _audioPlayer.openPlayer();
      _playerIsOpen = true;
      await _audioPlayer.setVolume(1.0);
      // Pre-warm the streaming player so hardware/sink is ready before first chunk arrives
      await _startStreamPlayback();
    } catch (e) {
      debugPrint("Error initializing audio pipeline: $e");
    }
  }

  @override
  void dispose() {
    _sessionActive = false;
    _sub?.cancel();
    _stopRecording();
    _recorder.dispose();
    _jitterBuffer.clear();
    if (_playerIsOpen) {
      if (_isPlayerStreaming) {
        _audioPlayer.stopPlayer();
      }
      _audioPlayer.closePlayer();
      _playerIsOpen = false;
    }
    _connection?.close();
    super.dispose();
  }

  void connectWebSocket() {
    try {
      _connection = KioskService.connectVoice(
        slug: params.slug,
        sessionId: params.sessionId,
        kioskToken: params.kioskToken,
      );

      _sub = _connection!.messages.listen(
        (msg) => _handleEvent(KioskVoiceEvent.fromJson(msg.data)),
        onError: (err) {
          state = state.copyWith(currentPhase: "Connection Error: $err");
        },
        onDone: () {
          state = state.copyWith(currentPhase: "Session Ended", isRecording: false);
          _sessionActive = false;
          _stopRecording();
        },
      );

      _connection!.start();
    } catch (e) {
      state = state.copyWith(currentPhase: "Failed to connect: $e");
    }
  }

  void _handleEvent(KioskVoiceEvent event) async {
    switch (event) {
      case ReadyEvent ready:
        state = state.copyWith(currentPhase: ready.phase ?? 'triage');
        _startRecording();

      case TriageStartedEvent():
        state = state.copyWith(currentPhase: "Triage Phase");

      case AgentSpeakingEvent agent:
        // Gate mic immediately when agent begins speaking
        _isMicGated = true;
        _isTurnBuffering = true;
        state = state.copyWith(
          agentText: agent.question ?? state.agentText,
          isRecording: false,
        );

      case AgentAudioChunkEvent chunk:
        if (chunk.audioB64 != null && chunk.audioB64!.isNotEmpty) {
          try {
            final pcmBytes = base64Decode(chunk.audioB64!);
            _enqueueAudioChunk(pcmBytes);
          } catch (e) {
            debugPrint("Error handling agent audio chunk: $e");
          }
        }

      case AgentDoneSpeakingEvent():
        // Un-gate mic when agent finishes speaking turn
        _isMicGated = false;
        _isTurnBuffering = false;
        if (_isRecordingActive) {
          state = state.copyWith(isRecording: true);
        }
        // Ensure any buffered audio is playing
        if (!_isPlayerStreaming && !_jitterBuffer.isEmpty) {
          _startStreamPlayback();
        } else {
          _drainJitterBuffer();
        }

      case UserSpeechStartedEvent():
        state = state.copyWith(userTranscript: "Listening...");

      case PartialTranscriptEvent pt:
        if (pt.text != null) {
          state = state.copyWith(userTranscript: pt.text!);
        }

      case CategoryIdentifiedEvent cat:
        state = state.copyWith(
          categoryLabel: cat.category?.label ?? cat.category?.key,
        );

      case ConsultationStartedEvent():
        state = state.copyWith(currentPhase: "Clinical Consultation");

      case SilenceNudgeEvent():
        break;

      case ConsultationEndedEvent():
        state = state.copyWith(currentPhase: "Consultation Concluded");

      case ResultReadyEvent resReady:
        state = state.copyWith(
          currentPhase: "Result Ready",
          resultReadyEvent: resReady,
        );
        // Primary trigger to stop recording
        _stopRecording();

      case EndedEvent():
        // Secondary safety net trigger to stop recording
        _stopRecording();
        state = state.copyWith(currentPhase: "Ended");
        _sessionActive = false;

      default:
        break;
    }
  }

  void _enqueueAudioChunk(Uint8List pcmBytes) {
    if (!_sessionActive) return;

    _jitterBuffer.add(pcmBytes);

    if (!_isPlayerStreaming) {
      if (!_isStartingStream && _jitterBuffer.totalBytes >= _preBufferThreshold) {
        _startStreamPlayback();
      }
    } else {
      if (_isTurnBuffering) {
        if (_jitterBuffer.totalBytes >= _preBufferThreshold) {
          _isTurnBuffering = false;
          _drainJitterBuffer();
        }
      } else {
        _drainJitterBuffer();
      }
    }
  }

  Future<void> _startStreamPlayback() async {
    if (_isPlayerStreaming || _isStartingStream || !_playerIsOpen || !_sessionActive) return;
    _isStartingStream = true;

    try {
      await _audioPlayer.startPlayerFromStream(
        codec: Codec.pcm16,
        interleaved: true,
        numChannels: 1,
        sampleRate: 24000,
        bufferSize: 2048,
        onBufferUnderflow: () {
          _drainJitterBuffer();
        },
      );
      _isPlayerStreaming = true;
      _isTurnBuffering = false;
      _drainJitterBuffer();
    } catch (e) {
      debugPrint("Error starting stream playback: $e");
    } finally {
      _isStartingStream = false;
    }
  }

  void _drainJitterBuffer() {
    final sink = _audioPlayer.uint8ListSink;
    if (!_playerIsOpen || !_isPlayerStreaming || sink == null) return;
    while (!_jitterBuffer.isEmpty) {
      final chunk = _jitterBuffer.readNext();
      if (chunk != null && chunk.isNotEmpty) {
        sink.add(chunk);
      }
    }
  }

  Future<void> _startRecording() async {
    if (_isRecordingActive) return;
    try {
      if (await _recorder.hasPermission()) {
        final stream = await _recorder.startStream(_recordConfig);
        _isRecordingActive = true;
        _isMicGated = false;
        state = state.copyWith(isRecording: true);

        _audioStreamSub = stream.listen((chunk) {
          if (_sessionActive && _isRecordingActive && !_isMicGated) {
            _connection?.sendAudioChunk(chunk);
          }
        });

        _amplitudeSub = _recorder
            .onAmplitudeChanged(const Duration(milliseconds: 40))
            .listen((amp) {
          state = state.copyWith(currentAmplitude: amp.current);
        });
      } else {
        debugPrint("Microphone permission denied");
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecordingActive && _audioStreamSub == null) return;
    _isRecordingActive = false;
    _isMicGated = false;
    try {
      await _audioStreamSub?.cancel();
      _audioStreamSub = null;
      await _amplitudeSub?.cancel();
      _amplitudeSub = null;
      await _recorder.stop();
    } catch (e) {
      debugPrint("Error stopping recording: $e");
    } finally {
      state = state.copyWith(isRecording: false);
    }
  }

  void endSessionAndClose() {
    _sessionActive = false;
    _stopRecording();
    if (_isPlayerStreaming) {
      _audioPlayer.stopPlayer();
      _isPlayerStreaming = false;
    }
    _connection?.close();
  }
}

final kioskConsultationServiceProvider = StateNotifierProvider.family<
    KioskConsultationService,
    KioskConsultationState,
    KioskConsultationParams>((ref, params) {
  return KioskConsultationService(params);
});
