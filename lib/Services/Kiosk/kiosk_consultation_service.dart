import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../../Models/kiosk_api_models.dart';
import '../../Models/kiosk_voice_events.dart';
import '../../Models/kiosk_voice_socket.dart';
import 'kiosk_service.dart';

class KioskConsultationState {
  final String currentPhase;
  final String agentText;
  final String userTranscript;
  final String? categoryLabel;
  final ResultReadyEvent? resultReadyEvent;
  final TicketingResult? ticketingResult;
  final bool isLoadingResult;
  final bool isRecording;
  final double currentAmplitude;

  const KioskConsultationState({
    this.currentPhase = "Connecting...",
    this.agentText = "Waiting for agent...",
    this.userTranscript = "",
    this.categoryLabel,
    this.resultReadyEvent,
    this.ticketingResult,
    this.isLoadingResult = false,
    this.isRecording = false,
    this.currentAmplitude = -60.0,
  });

  KioskConsultationState copyWith({
    String? currentPhase,
    String? agentText,
    String? userTranscript,
    String? categoryLabel,
    ResultReadyEvent? resultReadyEvent,
    TicketingResult? ticketingResult,
    bool? isLoadingResult,
    bool? isRecording,
    double? currentAmplitude,
  }) {
    return KioskConsultationState(
      currentPhase: currentPhase ?? this.currentPhase,
      agentText: agentText ?? this.agentText,
      userTranscript: userTranscript ?? this.userTranscript,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      resultReadyEvent: resultReadyEvent ?? this.resultReadyEvent,
      ticketingResult: ticketingResult ?? this.ticketingResult,
      isLoadingResult: isLoadingResult ?? this.isLoadingResult,
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

class KioskConsultationService extends StateNotifier<KioskConsultationState> {
  final KioskConsultationParams params;
  KioskVoiceConnection? _connection;
  StreamSubscription<KioskVoiceMessage>? _sub;
  final AudioRecorder _recorder = AudioRecorder();

  bool _soLoudInitialized = false;
  AudioSource? _currentAudioSource;
  SoundHandle? _currentSoundHandle;

  final BytesBuilder _pcmBuffer = BytesBuilder();
  bool _isPlaying = false;
  bool _sessionActive = true;
  bool _isRecordingActive = false;
  bool _isMicGated = false;
  bool _agentDoneSpeakingReceived = false;

  StreamSubscription<Uint8List>? _audioStreamSub;
  StreamSubscription<Amplitude>? _amplitudeSub;

  final _recordConfig = const RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
  );

  // Pre-buffer threshold: ~150ms at 24kHz mono 16-bit (24000 * 2 * 0.15 = 7200 bytes)
  static const int _preBufferThreshold = 7200;

  KioskConsultationService(this.params) : super(const KioskConsultationState()) {
    _initSoLoud();
    connectWebSocket();
  }

  Future<void> _initSoLoud() async {
    try {
      if (!SoLoud.instance.isInitialized) {
        await SoLoud.instance.init();
      }
      _soLoudInitialized = true;
    } catch (e) {
      debugPrint("Error initializing SoLoud: $e");
    }
  }

  @override
  void dispose() {
    _sessionActive = false;
    _stopCurrentAudio();
    _sub?.cancel();
    _audioStreamSub?.cancel();
    _amplitudeSub?.cancel();
    _recorder.dispose();
    _connection?.close();
    super.dispose();
  }

  void _ungateMic() {
    _isMicGated = false;
    if (_sessionActive && _isRecordingActive) {
      state = state.copyWith(isRecording: true);
    }
  }

  Future<void> _stopCurrentAudio() async {
    try {
      if (_currentSoundHandle != null && SoLoud.instance.isInitialized) {
        await SoLoud.instance.stop(_currentSoundHandle!);
        _currentSoundHandle = null;
      }
      if (_currentAudioSource != null && SoLoud.instance.isInitialized) {
        await SoLoud.instance.disposeSource(_currentAudioSource!);
        _currentAudioSource = null;
      }
    } catch (e) {
      debugPrint("Error stopping SoLoud audio: $e");
    } finally {
      _isPlaying = false;
      _pcmBuffer.clear();
      _ungateMic();
    }
  }

  Uint8List _createWavHeader(int pcmLength, {int sampleRate = 24000, int channels = 1, int bitsPerSample = 16}) {
    final int byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final int blockAlign = channels * (bitsPerSample ~/ 8);
    final int totalFileLen = pcmLength + 36;

    final ByteData header = ByteData(44);
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, totalFileLen, Endian.little);
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6d); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, pcmLength, Endian.little);

    return header.buffer.asUint8List();
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
        },
      );

      _connection!.start();
    } catch (e) {
      state = state.copyWith(currentPhase: "Failed to connect: $e");
    }
  }

  Future<void> fetchTicketingResult() async {
    if (state.ticketingResult != null || state.isLoadingResult) return;
    state = state.copyWith(isLoadingResult: true);
    try {
      final result = await KioskService.getTicketingResult(
        slug: params.slug,
        sessionId: params.sessionId,
        kioskToken: params.kioskToken,
      );
      state = state.copyWith(
        ticketingResult: result,
        isLoadingResult: false,
      );
    } catch (e) {
      debugPrint("Error fetching ticketing result: $e");
      final fallbackResult = TicketingResult(
        sessionId: params.sessionId,
        ticketNumber: "T-${params.sessionId.substring(0, 6).toUpperCase()}",
        summary: state.resultReadyEvent?.summary ?? (state.agentText.isNotEmpty ? state.agentText : "Consultation session completed."),
        phase: state.currentPhase,
        status: "completed",
        flags: [],
      );
      state = state.copyWith(
        ticketingResult: fallbackResult,
        isLoadingResult: false,
      );
    }
  }

  void _handleEvent(KioskVoiceEvent event) async {
    switch (event.type) {
      case 'ready':
        final ready = event as ReadyEvent;
        state = state.copyWith(currentPhase: ready.phase ?? 'triage');
        _startRecording();
        break;

      case 'triage_started':
        state = state.copyWith(currentPhase: "Triage Phase");
        break;

      case 'agent_speaking':
        final agent = event as AgentSpeakingEvent;
        if (agent.question != null) {
          state = state.copyWith(agentText: agent.question!);
        }
        _isMicGated = true;
        _agentDoneSpeakingReceived = false;
        state = state.copyWith(isRecording: false);
        break;

      case 'agent_audio_chunk':
        final chunk = event as AgentAudioChunkEvent;
        if (chunk.audioB64 != null && chunk.audioB64!.isNotEmpty) {
          try {
            _isMicGated = true;
            _agentDoneSpeakingReceived = false;
            state = state.copyWith(isRecording: false);
            final pcmBytes = base64Decode(chunk.audioB64!);
            _enqueueAudioChunk(pcmBytes);
          } catch (e) {
            debugPrint("Error handling agent audio chunk: $e");
          }
        }
        break;

      case 'agent_done_speaking':
        _agentDoneSpeakingReceived = true;
        if (!_isPlaying && _pcmBuffer.isEmpty) {
          _ungateMic();
        } else if (!_isPlaying && _pcmBuffer.length > 0) {
          _playBufferedAudio();
        }
        break;

      case 'user_speech_started':
        state = state.copyWith(userTranscript: "Listening...");
        await _stopCurrentAudio();
        _ungateMic();
        break;

      case 'partial_transcript':
        final pt = event as PartialTranscriptEvent;
        if (pt.text != null) {
          state = state.copyWith(userTranscript: pt.text!);
        }
        break;

      case 'category_identified':
        final cat = event as CategoryIdentifiedEvent;
        state = state.copyWith(
          categoryLabel: cat.category?.label ?? cat.category?.key,
        );
        break;

      case 'consultation_started':
        state = state.copyWith(currentPhase: "Clinical Consultation");
        break;

      case 'silence_nudge':
        break;

      case 'consultation_ended':
        state = state.copyWith(currentPhase: "Consultation Concluded");
        break;

      case 'result_ready':
        final resReady = event as ResultReadyEvent;
        state = state.copyWith(
          currentPhase: "Result Ready",
          resultReadyEvent: resReady,
        );
        _stopRecording();
        fetchTicketingResult();
        break;

      case 'ended':
        _stopRecording();
        state = state.copyWith(currentPhase: "Ended");
        _sessionActive = false;
        await _stopCurrentAudio();
        fetchTicketingResult();
        break;

      default:
        break;
    }
  }

  void _enqueueAudioChunk(Uint8List pcmBytes) {
    if (!_sessionActive) return;

    _pcmBuffer.add(pcmBytes);

    if (!_isPlaying && _pcmBuffer.length >= _preBufferThreshold) {
      _playBufferedAudio();
    }
  }

  Future<void> _playBufferedAudio() async {
    if (_isPlaying || !_soLoudInitialized || _pcmBuffer.isEmpty) return;
    _isPlaying = true;
    _isMicGated = true;
    state = state.copyWith(isRecording: false);

    try {
      final pcmBytes = _pcmBuffer.takeBytes();
      final wavHeader = _createWavHeader(pcmBytes.length, sampleRate: 24000, channels: 1, bitsPerSample: 16);

      final builder = BytesBuilder();
      builder.add(wavHeader);
      builder.add(pcmBytes);
      final wavBytes = builder.toBytes();

      final int durationMs = ((pcmBytes.length / 48000) * 1000).round();

      _currentAudioSource = await SoLoud.instance.loadMem(
        'agent_response_${DateTime.now().millisecondsSinceEpoch}',
        wavBytes,
      );

      if (_currentAudioSource != null) {
        _currentSoundHandle = await SoLoud.instance.play(_currentAudioSource!);

        // Un-gate mic only after playback completes AND agent_done_speaking event was received
        Future.delayed(Duration(milliseconds: durationMs + 100), () {
          if (_sessionActive) {
            _isPlaying = false;
            if (_pcmBuffer.isNotEmpty) {
              _playBufferedAudio();
            } else if (_agentDoneSpeakingReceived) {
              _ungateMic();
            }
          }
        });
      } else {
        _isPlaying = false;
        if (_pcmBuffer.isNotEmpty) {
          _playBufferedAudio();
        } else if (_agentDoneSpeakingReceived) {
          _ungateMic();
        }
      }
    } catch (e) {
      debugPrint("Error playing audio with SoLoud: $e");
      _isPlaying = false;
      if (_pcmBuffer.isNotEmpty) {
        _playBufferedAudio();
      } else if (_agentDoneSpeakingReceived) {
        _ungateMic();
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final stream = await _recorder.startStream(_recordConfig);
        _isRecordingActive = true;
        state = state.copyWith(isRecording: !_isMicGated);

        _audioStreamSub = stream.listen((chunk) {
          if (_sessionActive && _isRecordingActive && !_isMicGated) {
            _connection?.sendAudioChunk(chunk);
          }
        });

        _amplitudeSub = _recorder
            .onAmplitudeChanged(const Duration(milliseconds: 40))
            .listen((amp) {
          state = state.copyWith(
            currentAmplitude: _isMicGated ? -60.0 : amp.current,
          );
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

  Future<void> endSessionAndFetchResult() async {
    _sessionActive = false;
    _stopCurrentAudio();
    _stopRecording();
    _connection?.close();
    await fetchTicketingResult();
  }
}

final kioskConsultationServiceProvider = StateNotifierProvider.family<
    KioskConsultationService,
    KioskConsultationState,
    KioskConsultationParams>((ref, params) {
  return KioskConsultationService(params);
});
