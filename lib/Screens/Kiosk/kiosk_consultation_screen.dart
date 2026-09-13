import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:clinical_ai_app/Custom Widgets/custom_button.dart';
import 'package:clinical_ai_app/Models/kiosk_voice_events.dart';
import 'package:clinical_ai_app/Models/kiosk_voice_socket.dart';
import 'package:clinical_ai_app/Services/Kiosk/kiosk_service.dart';

class KioskConsultationScreen extends StatefulWidget {
  const KioskConsultationScreen({
    super.key,
    required this.slug,
    required this.sessionId,
    required this.kioskToken,
  });

  static const routeName = "/kiosk-consultation";

  final String slug;
  final String sessionId;
  final String kioskToken;

  @override
  State<KioskConsultationScreen> createState() => _KioskConsultationScreenState();
}

class _KioskConsultationScreenState extends State<KioskConsultationScreen> {
  KioskVoiceConnection? _connection;
  StreamSubscription<KioskVoiceMessage>? _sub;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<Uint8List>? _audioStreamSub;
  StreamSubscription<Amplitude>? _amplitudeSub;

  bool _isRecording = false;
  File? _currentAudioFile;

  String _currentPhase = "Connecting...";
  String _agentText = "Waiting for agent...";
  String _userTranscript = "";
  String? _categoryLabel;
  ResultReadyEvent? _resultReadyEvent;

  final _recordConfig = const RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
  );

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _audioStreamSub?.cancel();
    _amplitudeSub?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    _connection?.close();
    if (_currentAudioFile != null && _currentAudioFile!.existsSync()) {
      _currentAudioFile!.deleteSync();
    }
    super.dispose();
  }

  void _connectWebSocket() {
    try {
      _connection = KioskService.connectVoice(
        slug: widget.slug,
        sessionId: widget.sessionId,
        kioskToken: widget.kioskToken,
      );

      _sub = _connection!.messages.listen(
        (msg) => _handleEvent(KioskVoiceEvent.fromJson(msg.data)),
        onError: (err) {
          setState(() {
            _currentPhase = "Connection Error: $err";
          });
        },
        onDone: () {
          setState(() {
            _currentPhase = "Session Ended";
            _isRecording = false;
          });
        },
      );

      // Send initial start message per protocol
      _connection!.start();
    } catch (e) {
      setState(() {
        _currentPhase = "Failed to connect: $e";
      });
    }
  }

  void _handleEvent(KioskVoiceEvent event) async {
    switch (event.type) {
      case 'ready':
        final ready = event as ReadyEvent;
        setState(() {
          _currentPhase = ready.phase ?? 'triage';
        });
        _startRecording();
        break;

      case 'triage_started':
        setState(() => _currentPhase = "Triage Phase");
        break;

      case 'agent_speaking':
        final agent = event as AgentSpeakingEvent;
        if (agent.question != null) {
          setState(() => _agentText = agent.question!);
        }
        break;

      case 'agent_audio_chunk':
        final chunk = event as AgentAudioChunkEvent;
        if (chunk.audioB64 != null && chunk.audioB64!.isNotEmpty) {
          try {
            final bytes = base64Decode(chunk.audioB64!);
            _playAgentAudioBytes(bytes);
          } catch (e) {
            debugPrint("Error handling agent audio chunk: $e");
          }
        }
        break;

      case 'user_speech_started':
        setState(() => _userTranscript = "Listening...");
        break;

      case 'partial_transcript':
        final pt = event as PartialTranscriptEvent;
        if (pt.text != null) {
          setState(() => _userTranscript = pt.text!);
        }
        break;

      case 'category_identified':
        final cat = event as CategoryIdentifiedEvent;
        setState(() {
          _categoryLabel = cat.category?.label ?? cat.category?.key;
        });
        break;

      case 'consultation_started':
        setState(() => _currentPhase = "Clinical Consultation");
        break;

      case 'silence_nudge':
        // User was silent
        break;

      case 'consultation_ended':
        setState(() => _currentPhase = "Consultation Concluded");
        break;

      case 'result_ready':
        _resultReadyEvent = event as ResultReadyEvent;
        setState(() => _currentPhase = "Result Ready");
        _stopRecording();
        break;

      case 'ended':
        _stopRecording();
        setState(() => _currentPhase = "Ended");
        break;

      default:
        break;
    }
  }

  Future<void> _playAgentAudioBytes(Uint8List bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/kiosk_audio_${DateTime.now().millisecondsSinceEpoch}.pcm',
      );
      await file.writeAsBytes(bytes);

      final previous = _currentAudioFile;
      _currentAudioFile = file;
      if (previous != null && await previous.exists()) {
        await previous.delete();
      }

      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(DeviceFileSource(file.path));
    } catch (e) {
      debugPrint("Error playing agent audio chunk: $e");
    }
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final stream = await _recorder.startStream(_recordConfig);
      setState(() => _isRecording = true);

      _audioStreamSub = stream.listen((chunk) {
        _connection?.sendAudioChunk(chunk);
      });

      _amplitudeSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 50))
          .listen((amp) {
        // Amplitude updates if needed
      });
    }
  }

  Future<void> _stopRecording() async {
    await _audioStreamSub?.cancel();
    await _amplitudeSub?.cancel();
    await _recorder.stop();
    setState(() => _isRecording = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kiosk Consultation (${widget.sessionId.substring(0, 8)})"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppLayout.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(_currentPhase.toUpperCase()),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  if (_categoryLabel != null)
                    Chip(
                      label: Text("Category: $_categoryLabel"),
                      backgroundColor: Colors.green.withAlpha(50),
                    ),
                ],
              ),
              const SizedBox(height: AppLayout.space24),

              // Agent Speaking Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppLayout.space24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppLayout.panelRadius),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.smart_toy, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("AI Medical Agent", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        _agentText,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      if (_userTranscript.isNotEmpty) ...[
                        const Divider(),
                        Text(
                          "Patient: $_userTranscript",
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppLayout.space24),

              // Mic Waveform Indicator
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red.withAlpha(25) : Colors.grey.withAlpha(25),
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic : Icons.mic_off,
                    size: 36,
                    color: _isRecording ? Colors.red : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: AppLayout.space24),

              // Result View if ready
              if (_resultReadyEvent != null) ...[
                Card(
                  color: Colors.blue.withAlpha(25),
                  child: Padding(
                    padding: const EdgeInsets.all(AppLayout.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Consultation Summary Ready", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_resultReadyEvent!.summary ?? "No summary provided."),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppLayout.space16),
              ],

              CustomButton(
                text: "End Session & Return",
                onTap: () {
                  _stopRecording();
                  _connection?.close();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
