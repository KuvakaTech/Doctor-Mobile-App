import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:clinical_ai_app/Components/colors.dart';
import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:clinical_ai_app/Custom Widgets/custom_button.dart';
import 'package:clinical_ai_app/Custom Widgets/custom_confirmation_alert.dart';
import 'package:clinical_ai_app/Custom Widgets/Consultation/pulsating_mic_button.dart';
import 'package:clinical_ai_app/l10n/app_localizations.dart';

enum AudioRecordingState {
  idle,
  recording,
  paused,
  completed,
}

class AudioRecordingScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const AudioRecordingScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  static const routeName = "/audio-recording";

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen>
    with WidgetsBindingObserver {
  AudioRecordingState _recordingState = AudioRecordingState.idle;
  bool _isOffline = true; // Default to offline mode demo

  // Real Audio Hardware Controller
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _recordedFilePath;
  double _currentAmplitude = -50.0;

  // Previous Recordings List
  List<FileSystemEntity> _previousRecordings = [];
  String? _currentlyPlayingFilePath;

  // Recording Timer
  Timer? _timer;
  int _recordDurationSeconds = 0;

  // Playback Preview State
  bool _isPlayingPreview = false;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  double _previewProgress = 0.0;

  // Stream Subscriptions
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudioPlayerListeners();
    _loadPreviousRecordings();
  }

  void _initAudioPlayerListeners() {
    _positionSubscription = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted && _playbackDuration.inMilliseconds > 0) {
        setState(() {
          _playbackPosition = pos;
          _previewProgress = (pos.inMilliseconds / _playbackDuration.inMilliseconds).clamp(0.0, 1.0);
        });
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) {
        setState(() {
          _playbackDuration = dur;
        });
      }
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingPreview = false;
          _playbackPosition = Duration.zero;
          _previewProgress = 0.0;
          _currentlyPlayingFilePath = null;
        });
      }
    });
  }

  void _startAmplitudeListener() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      if (mounted && _recordingState == AudioRecordingState.recording) {
        setState(() {
          _currentAmplitude = amp.current;
        });
      }
    });
  }

  void _stopAmplitudeListener() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    if (mounted) {
      setState(() {
        _currentAmplitude = -50.0;
      });
    }
  }

  Future<void> _loadPreviousRecordings() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = appDocDir.listSync();
      final List<FileSystemEntity> patientRecordings = files.where((entity) {
        if (entity is File && entity.path.endsWith('.m4a')) {
          final fileName = entity.path.split('/').last.split('\\').last;
          return fileName.contains('rec_${widget.patientId}');
        }
        return false;
      }).toList();

      // Sort newest first
      patientRecordings.sort((a, b) {
        final aTime = (a as File).lastModifiedSync();
        final bTime = (b as File).lastModifiedSync();
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _previousRecordings = patientRecordings;
        });
      }
    } catch (e) {
      debugPrint("Failed to load previous recordings: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _stopAmplitudeListener();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached &&
        (_recordingState == AudioRecordingState.recording ||
            _recordingState == AudioRecordingState.paused)) {
      // Emergency safety fallback: finalize audio file on disk before OS terminates app process
      _stopRecording();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordDurationSeconds++;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _handleMicTap() async {
    switch (_recordingState) {
      case AudioRecordingState.idle:
        await _startRecording();
        break;

      case AudioRecordingState.recording:
        await _pauseRecording();
        break;

      case AudioRecordingState.paused:
        await _resumeRecording();
        break;

      case AudioRecordingState.completed:
        await _resetRecording();
        break;
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission required to record audio.")),
        );
        return;
      }

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '${appDocDir.path}/rec_${widget.patientId}_$timestamp.m4a';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
        numChannels: 1,
      );

      await _audioRecorder.start(config, path: filePath);

      if (!mounted) return;
      setState(() {
        _recordedFilePath = filePath;
        _recordingState = AudioRecordingState.recording;
        _recordDurationSeconds = 0;
      });

      _startTimer();
      _startAmplitudeListener();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start recording: $e")),
      );
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
    } catch (_) {}
    _pauseTimer();
    _stopAmplitudeListener();
    setState(() {
      _recordingState = AudioRecordingState.paused;
    });
  }

  Future<void> _resumeRecording() async {
    try {
      await _audioRecorder.resume();
    } catch (_) {}
    _startTimer();
    _startAmplitudeListener();
    setState(() {
      _recordingState = AudioRecordingState.recording;
    });
  }

  Future<void> _stopRecording() async {
    _stopTimer();
    _stopAmplitudeListener();
    String? path;
    try {
      path = await _audioRecorder.stop();
    } catch (_) {}

    setState(() {
      if (path != null) {
        _recordedFilePath = path;
      }
      _recordingState = AudioRecordingState.completed;
    });

    await _loadPreviousRecordings();
  }

  Future<void> _togglePreviewPlayback() async {
    if (_recordedFilePath == null || !File(_recordedFilePath!).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No recorded audio file found to play.")),
      );
      return;
    }

    if (_isPlayingPreview && _currentlyPlayingFilePath == _recordedFilePath) {
      await _audioPlayer.pause();
      setState(() {
        _isPlayingPreview = false;
      });
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
      setState(() {
        _currentlyPlayingFilePath = _recordedFilePath;
        _isPlayingPreview = true;
      });
    }
  }

  Future<void> _playPreviousRecording(String filePath) async {
    if (_currentlyPlayingFilePath == filePath && _isPlayingPreview) {
      await _audioPlayer.pause();
      setState(() {
        _isPlayingPreview = false;
      });
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(filePath));
      setState(() {
        _currentlyPlayingFilePath = filePath;
        _isPlayingPreview = true;
      });
    }
  }

  Future<void> _deletePreviousRecording(File file) async {
    showCustomConfirmationAlert(
      detail: "Do you want to delete this previous audio recording?",
      confirmText: "Delete",
      loadingText: "Deleting...",
      context: context,
      onPressed: () async {
        try {
          if (_currentlyPlayingFilePath == file.path) {
            await _audioPlayer.stop();
            _currentlyPlayingFilePath = null;
            _isPlayingPreview = false;
          }
          if (await file.exists()) {
            await file.delete();
          }
          await _loadPreviousRecordings();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Recording deleted from phone storage.")),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to delete recording: $e")),
            );
          }
        }
      },
    );
  }

  Future<void> _seekPreview(double value) async {
    if (_playbackDuration.inMilliseconds > 0) {
      final newPosition = Duration(
        milliseconds: (value * _playbackDuration.inMilliseconds).round(),
      );
      await _audioPlayer.seek(newPosition);
      setState(() {
        _previewProgress = value;
        _playbackPosition = newPosition;
      });
    }
  }

  Future<void> _resetRecording() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    _stopTimer();
    _stopAmplitudeListener();

    setState(() {
      _recordedFilePath = null;
      _recordingState = AudioRecordingState.idle;
      _recordDurationSeconds = 0;
      _isPlayingPreview = false;
      _currentlyPlayingFilePath = null;
      _playbackPosition = Duration.zero;
      _playbackDuration = Duration.zero;
      _previewProgress = 0.0;
    });

    await _loadPreviousRecordings();
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.radius16),
        ),
        title: const Text("Recording in Progress"),
        content: const Text(
          "You have an active audio recording session. Would you like to stop and save it before leaving, or discard it?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _resetRecording();
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              "Discard",
              style: TextStyle(color: AppColors.error),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _stopRecording();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save & Leave"),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDurationFromDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _handleSubmit() {
    final message = _isOffline
        ? "Recording saved locally and queued for background sync!"
        : "Recording submitted for online processing!";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isOffline ? LucideIcons.cloudOff : LucideIcons.cloudUpload,
              color: AppColors.surface,
              size: 20,
            ),
            const SizedBox(width: AppLayout.space8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _isOffline ? AppColors.warning : AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bool isRecordingActive =
        _recordingState == AudioRecordingState.recording ||
        _recordingState == AudioRecordingState.paused;

    return PopScope(
      canPop: !isRecordingActive,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _showExitConfirmationDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.audioRecordingTitle(widget.patientName)),
          actions: [
            // Connection Mode Switcher Badge
            Padding(
              padding: const EdgeInsets.only(right: AppLayout.space16),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isOffline = !_isOffline;
                  });
                },
                borderRadius: BorderRadius.circular(AppLayout.radius20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppLayout.space12,
                    vertical: AppLayout.space6,
                  ),
                  decoration: BoxDecoration(
                    color: _isOffline
                        ? AppColors.warningContainer
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppLayout.radius20),
                    border: Border.all(
                      color: _isOffline ? AppColors.warning : theme.colorScheme.primary,
                      width: AppLayout.borderThin,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isOffline ? LucideIcons.wifiOff : LucideIcons.wifi,
                        size: AppLayout.iconSmall,
                        color: _isOffline ? AppColors.warning : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppLayout.space6),
                      Text(
                        _isOffline ? l10n.offlineModeBadge : l10n.onlineModeBadge,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isOffline ? AppColors.warning : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppLayout.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Patient & Connection Banner Card
                _buildPatientHeaderCard(theme, l10n),

                const SizedBox(height: AppLayout.space24),

                // 2. Main Recording Area Card
                Container(
                  padding: const EdgeInsets.all(AppLayout.space24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppLayout.panelRadius),
                    border: Border.all(
                      color: theme.dividerColor,
                      width: AppLayout.borderThin,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(
                          theme.brightness == Brightness.light ? 10 : 35,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status Label
                      Text(
                        _getStatusText(l10n),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _getStatusColor(theme),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppLayout.space12),

                      // Timer Display
                      Text(
                        _formatDuration(_recordDurationSeconds),
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 48,
                          letterSpacing: 2.0,
                          color: _recordingState == AudioRecordingState.recording
                              ? AppColors.error
                              : theme.textTheme.headlineLarge?.color,
                        ),
                      ),

                      const SizedBox(height: AppLayout.space32),

                      // Animated Mic Button with Real-time Amplitude Responsiveness
                      PulsatingMicButton(
                        isRecording: _recordingState == AudioRecordingState.recording,
                        isPaused: _recordingState == AudioRecordingState.paused,
                        isCompleted: _recordingState == AudioRecordingState.completed,
                        amplitude: _currentAmplitude,
                        onTap: _handleMicTap,
                        size: 70.0,
                      ),

                      const SizedBox(height: AppLayout.space32),

                      // Instruction / Hint Text
                      Text(
                        _recordingState == AudioRecordingState.idle
                            ? l10n.tapToStartRecording
                            : _recordingState == AudioRecordingState.completed
                                ? "Review recording below or tap re-record to start over."
                                : "Tap button to pause or resume recording.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),

                      if (_recordedFilePath != null &&
                          _recordingState == AudioRecordingState.completed) ...[
                        const SizedBox(height: AppLayout.space12),
                        Text(
                          "Saved to: ${File(_recordedFilePath!).path.split('/').last}",
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppLayout.space24),

                // 3. Playback Preview Player Bar (When completed)
                if (_recordingState == AudioRecordingState.completed) ...[
                  _buildPlaybackPreviewBar(theme, l10n),
                  const SizedBox(height: AppLayout.space16),
                ],

                // 4. In-recording controls (Pause / Stop / Resume)
                if (_recordingState == AudioRecordingState.recording ||
                    _recordingState == AudioRecordingState.paused) ...[
                  _buildInRecordingControls(theme, l10n),
                  const SizedBox(height: AppLayout.space16),
                ],

                // 5. Final Action Button
                CustomButton(
                  text: _isOffline ? l10n.saveToQueue : l10n.uploadConsultationAudio,
                  loadingText: l10n.processingAudio,
                  isPseudoDisabled: _recordingState != AudioRecordingState.completed,
                  onTap: _recordingState == AudioRecordingState.completed ? _handleSubmit : null,
                ),

                // 6. Previous Recordings Panel
                _buildPreviousRecordingsPanel(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeaderCard(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppLayout.radius16),
        border: Border.all(
          color: theme.dividerColor,
          width: AppLayout.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppLayout.space8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.user,
                  color: theme.colorScheme.primary,
                  size: AppLayout.iconMedium,
                ),
              ),
              const SizedBox(width: AppLayout.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patientName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Patient ID: ${widget.patientId}",
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.space12),
          Container(
            padding: const EdgeInsets.all(AppLayout.space10),
            decoration: BoxDecoration(
              color: _isOffline
                  ? AppColors.warningContainer.withAlpha(100)
                  : theme.colorScheme.primaryContainer.withAlpha(100),
              borderRadius: BorderRadius.circular(AppLayout.radius8),
            ),
            child: Row(
              children: [
                Icon(
                  _isOffline ? LucideIcons.info : LucideIcons.checkCircle2,
                  size: AppLayout.iconSmall,
                  color: _isOffline ? AppColors.warning : theme.colorScheme.primary,
                ),
                const SizedBox(width: AppLayout.space8),
                Expanded(
                  child: Text(
                    _isOffline ? l10n.offlineSyncNotice : l10n.onlineSyncNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _isOffline ? AppColors.warning : theme.colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInRecordingControls(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        // Pause / Resume Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _handleMicTap,
            icon: Icon(
              _recordingState == AudioRecordingState.recording
                  ? LucideIcons.pause
                  : LucideIcons.play,
              size: AppLayout.iconSmall,
            ),
            label: Text(
              _recordingState == AudioRecordingState.recording
                  ? l10n.pauseRecording
                  : l10n.resumeRecording,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppLayout.space12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppLayout.radius12),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppLayout.space12),

        // Stop Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _stopRecording,
            icon: const Icon(LucideIcons.square, size: AppLayout.iconSmall),
            label: Text(l10n.stopRecording),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppLayout.space12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppLayout.radius12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackPreviewBar(ThemeData theme, AppLocalizations l10n) {
    final isPlayingActiveRecording =
        _isPlayingPreview && _currentlyPlayingFilePath == _recordedFilePath;

    return Container(
      padding: const EdgeInsets.all(AppLayout.space12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppLayout.radius16),
        border: Border.all(
          color: theme.dividerColor,
          width: AppLayout.borderThin,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _togglePreviewPlayback,
            icon: Icon(
              isPlayingActiveRecording ? LucideIcons.pause : LucideIcons.play,
              color: theme.colorScheme.primary,
            ),
          ),
          Expanded(
            child: Slider(
              value: isPlayingActiveRecording ? _previewProgress : 0.0,
              onChanged: _seekPreview,
            ),
          ),
          Text(
            _formatDurationFromDuration(
              isPlayingActiveRecording ? _playbackPosition : Duration.zero,
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: AppLayout.space8),
          IconButton(
            onPressed: _resetRecording,
            tooltip: l10n.reRecord,
            icon: const Icon(LucideIcons.rotateCcw, size: AppLayout.iconSmall),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousRecordingsPanel(ThemeData theme) {
    if (_previousRecordings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: AppLayout.space24),
      padding: const EdgeInsets.all(AppLayout.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppLayout.panelRadius),
        border: Border.all(
          color: theme.dividerColor,
          width: AppLayout.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.history,
                size: AppLayout.iconMedium,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppLayout.space8),
              Text(
                "Previous Recordings (${_previousRecordings.length})",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.space12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _previousRecordings.length,
            separatorBuilder: (context, index) => const Divider(height: AppLayout.space16),
            itemBuilder: (context, index) {
              final file = _previousRecordings[index] as File;
              final fileName = file.path.split('/').last.split('\\').last;
              final lastModified = file.lastModifiedSync();
              final fileSizeKb = (file.lengthSync() / 1024).toStringAsFixed(1);
              final isPlayingThis = _isPlayingPreview && _currentlyPlayingFilePath == file.path;

              return Row(
                children: [
                  IconButton(
                    onPressed: () => _playPreviousRecording(file.path),
                    icon: Icon(
                      isPlayingThis ? LucideIcons.pause : LucideIcons.play,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppLayout.space8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${DateFormat('d MMM yyyy, hh:mm a').format(lastModified)} · $fileSizeKb KB",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deletePreviousRecording(file),
                    icon: const Icon(
                      LucideIcons.trash2,
                      color: AppColors.error,
                      size: AppLayout.iconSmall,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getStatusText(AppLocalizations l10n) {
    switch (_recordingState) {
      case AudioRecordingState.idle:
        return l10n.readyToRecord;
      case AudioRecordingState.recording:
        return l10n.recordingInProgress;
      case AudioRecordingState.paused:
        return l10n.recordingPaused;
      case AudioRecordingState.completed:
        return l10n.recordingComplete;
    }
  }

  Color _getStatusColor(ThemeData theme) {
    switch (_recordingState) {
      case AudioRecordingState.idle:
        return theme.textTheme.titleMedium?.color ?? Colors.black;
      case AudioRecordingState.recording:
        return AppColors.error;
      case AudioRecordingState.paused:
        return AppColors.warning;
      case AudioRecordingState.completed:
        return AppColors.success;
    }
  }
}
