import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual feedback overlay for ArUco marker detection during scanning.
///
/// Displays 4 L-shaped corner brackets that change color based on
/// marker detection status. Includes pulsing animation for undetected
/// corners and stability progress indicator when aligning.
class AlignmentOverlay extends StatefulWidget {
  /// Number of markers currently detected (0-4)
  final int markersDetected;

  /// True when all 4 markers found and stabilizing for auto-capture
  final bool isAligning;

  /// Milliseconds of stability progress (0-500)
  final int stabilityMs;

  const AlignmentOverlay({
    super.key,
    required this.markersDetected,
    this.isAligning = false,
    this.stabilityMs = 0,
  });

  @override
  State<AlignmentOverlay> createState() => _AlignmentOverlayState();
}

class _AlignmentOverlayState extends State<AlignmentOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: widget.markersDetected == 4
          ? 'All 4 corner markers detected. Hold steady.'
          : '${widget.markersDetected} of 4 corner markers detected.',
      child: Stack(
        children: [
          // Top-left corner
          Positioned(
            top: 24,
            left: 24,
            child: _CornerBracket(
              corner: _Corner.topLeft,
              isDetected: widget.markersDetected >= 1,
              pulseAnimation: reduceMotion ? null : _pulseAnimation,
              isAligning: widget.isAligning,
            ),
          ),
          // Top-right corner
          Positioned(
            top: 24,
            right: 24,
            child: _CornerBracket(
              corner: _Corner.topRight,
              isDetected: widget.markersDetected >= 2,
              pulseAnimation: reduceMotion ? null : _pulseAnimation,
              isAligning: widget.isAligning,
            ),
          ),
          // Bottom-right corner
          Positioned(
            bottom: 104, // Above bottom bar
            right: 24,
            child: _CornerBracket(
              corner: _Corner.bottomRight,
              isDetected: widget.markersDetected >= 3,
              pulseAnimation: reduceMotion ? null : _pulseAnimation,
              isAligning: widget.isAligning,
            ),
          ),
          // Bottom-left corner
          Positioned(
            bottom: 104,
            left: 24,
            child: _CornerBracket(
              corner: _Corner.bottomLeft,
              isDetected: widget.markersDetected >= 4,
              pulseAnimation: reduceMotion ? null : _pulseAnimation,
              isAligning: widget.isAligning,
            ),
          ),
          // Center instruction text and progress
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isAligning) ...[
                  _StabilityProgressRing(
                    progress: widget.stabilityMs / 500.0,
                  ),
                  const SizedBox(height: 16),
                ],
                _InstructionText(
                  isAligning: widget.isAligning,
                  markersDetected: widget.markersDetected,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Corner { topLeft, topRight, bottomRight, bottomLeft }

class _CornerBracket extends StatelessWidget {
  final _Corner corner;
  final bool isDetected;
  final Animation<double>? pulseAnimation;
  final bool isAligning;

  static const _size = 60.0;
  static const _strokeWidth = 4.0;
  static const _cornerRadius = 8.0;
  static const _notDetectedColor = Color(0xFFFF6B6B);
  static const _detectedColor = Color(0xFF4ECDC4);
  static const _aligningColor = Color(0xFF2ECC71);

  const _CornerBracket({
    required this.corner,
    required this.isDetected,
    required this.pulseAnimation,
    required this.isAligning,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAligning
        ? _aligningColor
        : isDetected
            ? _detectedColor
            : _notDetectedColor;

    Widget bracket = CustomPaint(
      size: const Size(_size, _size),
      painter: _CornerBracketPainter(
        corner: corner,
        color: color,
        strokeWidth: _strokeWidth,
        cornerRadius: _cornerRadius,
      ),
    );

    // Apply pulsing animation only to undetected corners
    if (!isDetected && pulseAnimation != null) {
      bracket = AnimatedBuilder(
        animation: pulseAnimation!,
        builder: (context, child) => Opacity(
          opacity: pulseAnimation!.value,
          child: child,
        ),
        child: bracket,
      );
    }

    return bracket;
  }
}

class _CornerBracketPainter extends CustomPainter {
  final _Corner corner;
  final Color color;
  final double strokeWidth;
  final double cornerRadius;

  _CornerBracketPainter({
    required this.corner,
    required this.color,
    required this.strokeWidth,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final armLength = w * 0.6;

    switch (corner) {
      case _Corner.topLeft:
        // Vertical arm going down
        path.moveTo(0, armLength);
        path.lineTo(0, cornerRadius);
        path.quadraticBezierTo(0, 0, cornerRadius, 0);
        // Horizontal arm going right
        path.lineTo(armLength, 0);
        break;
      case _Corner.topRight:
        // Horizontal arm going left
        path.moveTo(w - armLength, 0);
        path.lineTo(w - cornerRadius, 0);
        path.quadraticBezierTo(w, 0, w, cornerRadius);
        // Vertical arm going down
        path.lineTo(w, armLength);
        break;
      case _Corner.bottomRight:
        // Vertical arm going up
        path.moveTo(w, h - armLength);
        path.lineTo(w, h - cornerRadius);
        path.quadraticBezierTo(w, h, w - cornerRadius, h);
        // Horizontal arm going left
        path.lineTo(w - armLength, h);
        break;
      case _Corner.bottomLeft:
        // Horizontal arm going right
        path.moveTo(armLength, h);
        path.lineTo(cornerRadius, h);
        path.quadraticBezierTo(0, h, 0, h - cornerRadius);
        // Vertical arm going up
        path.lineTo(0, h - armLength);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerBracketPainter oldDelegate) =>
      corner != oldDelegate.corner ||
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      cornerRadius != oldDelegate.cornerRadius;
}

class _InstructionText extends StatelessWidget {
  final bool isAligning;
  final int markersDetected;

  const _InstructionText({
    required this.isAligning,
    required this.markersDetected,
  });

  @override
  Widget build(BuildContext context) {
    final text = isAligning
        ? 'Hold steady...'
        : markersDetected == 0
            ? 'Point camera at answer sheet'
            : '$markersDetected/4 markers detected';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StabilityProgressRing extends StatelessWidget {
  final double progress;

  const _StabilityProgressRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CircularProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        strokeWidth: 4,
        backgroundColor: Colors.white.withValues(alpha: 0.3),
        valueColor: AlwaysStoppedAnimation<Color>(
          Color.lerp(
            const Color(0xFF4ECDC4),
            const Color(0xFF2ECC71),
            progress,
          )!,
        ),
      ),
    );
  }
}
