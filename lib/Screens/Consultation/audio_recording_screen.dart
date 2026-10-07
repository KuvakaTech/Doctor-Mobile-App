import 'package:flutter/material.dart';
import '../../Components/layout_constants.dart';

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

class _AudioRecordingScreenState extends State<AudioRecordingScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Audio Recording - ${widget.patientName}"),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppLayout.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppLayout.space16),
                Text(
                  "Audio Recording Screen",
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppLayout.space8),
                Text(
                  "Patient: ${widget.patientName} (ID: ${widget.patientId})",
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
