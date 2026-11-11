import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:clinical_ai_app/Components/colors.dart';

class PulsatingMicButton extends StatefulWidget {
  final bool isRecording;
  final bool isPaused;
  final bool isCompleted;
  final bool isConnecting;
  final double amplitude;
  final VoidCallback onTap;
  final double size;

  const PulsatingMicButton({
    super.key,
    required this.isRecording,
    this.isPaused = false,
    this.isCompleted = false,
    this.isConnecting = false,
    this.amplitude = 0.0,
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
    final double volumeFactor = widget.amplitude != 0.0
        ? ((widget.amplitude + 50) / 40).clamp(0.0, 1.0)
        : 0.8;

    final Color buttonColor = widget.isRecording
        ? AppColors.error
        : (widget.isPaused ? AppColors.warning : AppColors.brand);

    final IconData iconData = widget.isRecording
        ? (widget.amplitude != 0.0 ? LucideIcons.square : LucideIcons.pause)
        : (widget.isPaused
            ? LucideIcons.play
            : (widget.isCompleted ? LucideIcons.rotateCcw : LucideIcons.mic));

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
                        shape: BoxShape.circle,
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
                color: buttonColor,
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withAlpha((100 * volumeFactor).toInt().clamp(20, 100)),
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
                      iconData,
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
