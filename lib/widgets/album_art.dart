import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Curated artwork gradients.
///
/// The app ships no image assets — this list is the entire visual identity of
/// the library. Every entry leans warm-orange or cool-blue so a grid of them
/// still reads as one collection.
const List<List<Color>> _artGradients = <List<Color>>[
  <Color>[Color(0xFFFF9A4D), Color(0xFFF05A28)], // ember
  <Color>[Color(0xFF3B82F6), Color(0xFF0EA5E9)], // coast
  <Color>[Color(0xFF6366F1), Color(0xFF2563EB)], // indigo
  <Color>[Color(0xFFFB7185), Color(0xFFF97316)], // sunset
  <Color>[Color(0xFF0EA5E9), Color(0xFF1E3A8A)], // deep
  <Color>[Color(0xFFF59E0B), Color(0xFFEF4444)], // amber
  <Color>[Color(0xFF10B981), Color(0xFF0891B2)], // mint
  <Color>[Color(0xFF8B5CF6), Color(0xFFEC4899)], // orchid
  <Color>[Color(0xFF14B8A6), Color(0xFF2563EB)], // lagoon
  <Color>[Color(0xFFF97316), Color(0xFFBE185D)], // magma
  <Color>[Color(0xFF38BDF8), Color(0xFF7C3AED)], // sky
  <Color>[Color(0xFFEF4444), Color(0xFF7C2D12)], // clay
];

/// Deterministic gradient for a given seed, so the same track always looks the
/// same and the player can tint its background to match.
LinearGradient albumGradient(int seed) {
  final pair = _artGradients[seed.abs() % _artGradients.length];
  return LinearGradient(
    colors: pair,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// The two raw colours behind [albumGradient] — for glow and tint effects.
List<Color> albumColors(int seed) =>
    _artGradients[seed.abs() % _artGradients.length];

/// Procedurally generated cover art: a gradient, a soft light source, and a
/// waveform motif.
///
/// Generating artwork instead of shipping files keeps the project asset-free
/// while still giving every track a distinct, on-brand cover.
class AlbumArt extends StatelessWidget {
  const AlbumArt({
    super.key,
    required this.seed,
    this.size,
    this.width,
    this.height,
    this.radius = 18,
    this.circle = false,
    this.showWave = true,
    this.border,
  });

  final int seed;
  final double? size;
  final double? width;
  final double? height;
  final double radius;
  final bool circle;
  final bool showWave;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;

    final art = DecoratedBox(
      decoration: BoxDecoration(gradient: albumGradient(seed)),
      child: CustomPaint(
        painter: _ArtMotifPainter(seed: seed, showWave: showWave),
        child: const SizedBox.expand(),
      ),
    );

    final clipped = circle
        ? ClipOval(child: art)
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: art,
          );

    return SizedBox(
      width: w,
      height: h,
      child: border == null
          ? clipped
          : DecoratedBox(
              decoration: BoxDecoration(
                shape: circle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: circle ? null : BorderRadius.circular(radius),
                border: border,
              ),
              child: clipped,
            ),
    );
  }
}

class _ArtMotifPainter extends CustomPainter {
  const _ArtMotifPainter({required this.seed, required this.showWave});

  final int seed;
  final bool showWave;

  @override
  void paint(Canvas canvas, Size size) {
    // A soft light source in the upper-left corner gives the flat gradient
    // some depth.
    final lightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: .30),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * .26, size.height * .22),
          radius: size.shortestSide * .62,
        ),
      );
    canvas.drawRect(Offset.zero & size, lightPaint);

    final rng = math.Random(seed * 977 + 13);

    // Two faint sine strokes across the lower half: a suggestion of a waveform
    // rather than a literal one.
    for (var line = 0; line < 2; line++) {
      final path = Path();
      final baseY = size.height * (line == 0 ? .70 : .82);
      final amp = size.height * (.055 + line * .02);
      final phase = rng.nextDouble() * math.pi * 2;
      for (double x = 0; x <= size.width; x += size.width / 38) {
        final t = x / size.width;
        final y =
            baseY +
            math.sin(t * math.pi * (2.4 + line) + phase) * amp;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.shortestSide * .014
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: line == 0 ? .34 : .20),
      );
    }

    if (!showWave) return;

    // A short bar cluster in the lower-left, the "sound" motif.
    const bars = 5;
    final barW = size.shortestSide * .035;
    final gap = barW * .85;
    final startX = size.width * .13;
    final baseline = size.height * .50;
    for (var i = 0; i < bars; i++) {
      final height = size.height * (.10 + rng.nextDouble() * .22);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          startX + i * (barW + gap),
          baseline - height / 2,
          barW,
          height,
        ),
        Radius.circular(barW),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = Colors.white.withValues(alpha: .55),
      );
    }
  }

  @override
  bool shouldRepaint(_ArtMotifPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.showWave != showWave;
}

/// A vinyl disc: concentric grooves around a miniaturised cover.
///
/// Drawn rather than composed from images so it stays crisp at any size — it
/// is used at 60 px in the mini player and at 320 px on the player screen.
class VinylDisc extends StatelessWidget {
  const VinylDisc({
    super.key,
    required this.seed,
    required this.size,
    this.rotation = 0,
    this.showHighlight = true,
  });

  final int seed;
  final double size;

  /// Turns, 0..1. Driven by the player's rotation controller.
  final double rotation;
  final bool showHighlight;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: rotation * 2 * math.pi,
            child: CustomPaint(
              size: Size.square(size),
              painter: _VinylPainter(
                groove: palette.textPrimary.withValues(
                  alpha: context.isDark ? .22 : .10,
                ),
                sheen: Colors.white.withValues(alpha: showHighlight ? .22 : 0),
              ),
            ),
          ),
          AlbumArt(
            seed: seed,
            size: size * .56,
            circle: true,
            showWave: false,
          ),
        ],
      ),
    );
  }
}

class _VinylPainter extends CustomPainter {
  const _VinylPainter({required this.groove, required this.sheen});

  final Color groove;
  final Color sheen;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    // Body of the disc.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF2A2F3C),
            const Color(0xFF14171F),
            const Color(0xFF23262F),
          ],
          stops: const [0, .72, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Grooves.
    final groovePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = groove;
    for (double r = radius * .62; r < radius * .98; r += radius * .045) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // A single specular sweep so the disc reads as glossy.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * .78),
      -math.pi * .75,
      math.pi * .5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .16
        ..strokeCap = StrokeCap.round
        ..color = sheen,
    );
  }

  @override
  bool shouldRepaint(_VinylPainter oldDelegate) =>
      oldDelegate.groove != groove || oldDelegate.sheen != sheen;
}
