import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:clinical_ai_app/Components/colors.dart';
import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:clinical_ai_app/Custom Widgets/custom_button.dart';
import 'package:clinical_ai_app/Services/Kiosk/kiosk_consultation_service.dart';
import 'package:clinical_ai_app/Screens/Kiosk/kiosk_result_screen.dart';

class KioskConsultationScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final params = KioskConsultationParams(
      slug: slug,
      sessionId: sessionId,
      kioskToken: kioskToken,
    );
    final state = ref.watch(kioskConsultationServiceProvider(params));
    final service = ref.read(kioskConsultationServiceProvider(params).notifier);

    // Automatically navigate to KioskResultScreen when ticketing result is fetched
    ref.listen(kioskConsultationServiceProvider(params), (previous, next) {
      if (next.ticketingResult != null && previous?.ticketingResult == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => KioskResultScreen(result: next.ticketingResult!),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("Kiosk Consultation (${sessionId.substring(0, 8)})"),
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
                    label: Text(state.currentPhase.toUpperCase()),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  if (state.categoryLabel != null)
                    Chip(
                      label: Text("Category: ${state.categoryLabel}"),
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
                        state.agentText,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      if (state.userTranscript.isNotEmpty) ...[
                        const Divider(),
                        Text(
                          "Patient: ${state.userTranscript}",
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppLayout.space24),

              // Pulsating Mic Button with Amplitude Animation
              Center(
                child: PulsatingMicButton(
                  isRecording: state.isRecording,
                  isConnecting: state.isLoadingResult,
                  amplitude: state.currentAmplitude,
                  onTap: () {},
                ),
              ),
              const SizedBox(height: AppLayout.space24),

              // Result View if ready
              if (state.resultReadyEvent != null) ...[
                Card(
                  color: Colors.blue.withAlpha(25),
                  child: Padding(
                    padding: const EdgeInsets.all(AppLayout.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Consultation Summary Ready", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(state.resultReadyEvent!.summary ?? "No summary provided."),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppLayout.space16),
              ],

              CustomButton(
                text: state.isLoadingResult ? "Fetching Result..." : "End Session & View Result",
                onTap: () async {
                  await service.endSessionAndFetchResult();
                  if (context.mounted && ref.read(kioskConsultationServiceProvider(params)).ticketingResult == null) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PulsatingMicButton extends StatefulWidget {
  final bool isRecording;
  final bool isConnecting;
  final double amplitude;
  final VoidCallback onTap;
  final double size;

  const PulsatingMicButton({
    super.key,
    required this.isRecording,
    required this.isConnecting,
    required this.amplitude,
    required this.onTap,
    this.size = 65.0,
  });

  @override
  State<PulsatingMicButton> createState() => _PulsatingMicButtonState();
}

class _PulsatingMicButtonState extends State<PulsatingMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isRecording) _controller.repeat();
  }

  @override
  void didUpdateWidget(PulsatingMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double volumeFactor = ((widget.amplitude + 50) / 40).clamp(0.0, 1.0);

    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (widget.isRecording)
              ...List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final double progress =
                        (_controller.value + (index / 3)) % 1.0;
                    final double spread =
                        progress * (widget.size * 0.9) * volumeFactor;
                    final double opacity = (1.0 - progress) * volumeFactor;

                    return Container(
                      width: widget.size + spread,
                      height: widget.size + spread,
                      decoration: BoxDecoration(
                        shape:
                            BoxShape.circle,
                        color:
                            AppColors.error.withAlpha((180 * opacity).toInt()),
                      ),
                    );
                  },
                );
              }),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording ? AppColors.error : AppColors.brand,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isRecording ? AppColors.error : AppColors.brand)
                        .withAlpha((100 * volumeFactor).toInt().clamp(20, 100)),
                    blurRadius: (widget.size / 6) + (volumeFactor * 10),
                    spreadRadius: 1 + (volumeFactor * 4),
                  ),
                ],
              ),
              child: widget.isConnecting
                  ? Padding(
                      padding: EdgeInsets.all(widget.size * 0.25),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      widget.isRecording ? LucideIcons.square : LucideIcons.mic,
                      color: AppColors.surface,
                      size: widget.size * 0.43,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
