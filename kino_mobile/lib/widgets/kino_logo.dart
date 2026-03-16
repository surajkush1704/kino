import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// 🏛️ THE ZEN MINIMALIST "KINO" LOGO 🏛️
// (Chiseled Gold with Dynamic Light Sweep)
// ==========================================
class KinoLogo extends StatelessWidget {
  final double scale;
  final double sweepValue; // Added this to control the light animation

  const KinoLogo({
    super.key,
    this.scale = 1.0,
    this.sweepValue = 0.5, // Default center position for static screens
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.cinzelDecorative(
      fontSize: 42.0 * scale,
      fontWeight: FontWeight.w700,
      letterSpacing: 10.0 * scale,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. THE AMBIENT FLOOR GLOW
        Text(
          "KINO",
          style: textStyle.copyWith(
            color: Colors.transparent,
            shadows: [
              Shadow(
                color: const Color(0xFFB8860B).withOpacity(0.15),
                blurRadius: 20.0 * scale,
              ),
            ],
          ),
        ),

        // 2. THE KINTSUGI GOLD GRADIENT WITH ANIMATED SWEEP
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            // The sweepValue moves the Champagne Gold highlight across the letters
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFB8860B), // Antique Bronze
                Color(0xFFF7E7CE), // Champagne Gold (The Highlight)
                Color(0xFFD4AF37), // Metallic Gold
                Color(0xFFB8860B), // Antique Bronze
              ],
              stops: [
                (sweepValue - 0.2).clamp(0.0, 1.0),
                sweepValue.clamp(0.0, 1.0),
                (sweepValue + 0.1).clamp(0.0, 1.0),
                (sweepValue + 0.4).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Text("KINO", style: textStyle),
        ),

        // 3. THE CHISELED RIM LIGHT (Fine Golden Stroke)
        Text(
          "KINO",
          style: textStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5 * scale
              ..color = const Color(0xFFF7E7CE).withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
