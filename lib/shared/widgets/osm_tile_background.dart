import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hand-rolled OSM tile background (no google_maps dependency).
///
/// Web-mercator tile math with a lightweight `CustomPainter` map by default.
/// Live OSM network tiles are opt-in because loading a tile grid during route
/// transitions can overwhelm some Android devices.
/// Extracted from the client app's `email_login_page.dart`
/// and parameterized by center coordinates.
class OsmTileBackground extends StatelessWidget {
  const OsmTileBackground({
    super.key,
    required this.offset,
    this.latitude = 19.2836,
    this.longitude = 72.8727,
    this.zoom = 16,
    this.useNetworkTiles = false,
  });

  final Offset offset;
  final double latitude;
  final double longitude;
  final int zoom;
  final bool useNetworkTiles;

  double _longToTileX(double longitude, int zoom) {
    return (longitude + 180) / 360 * math.pow(2, zoom);
  }

  double _latToTileY(double latitude, int zoom) {
    final latRad = latitude * math.pi / 180;
    return (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
        2 *
        math.pow(2, zoom);
  }

  @override
  Widget build(BuildContext context) {
    final centerX = _longToTileX(longitude, zoom);
    final centerY = _latToTileY(latitude, zoom);
    final originX = centerX.floor() - 2;
    final originY = centerY.floor() - 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!useNetworkTiles) {
          return ColoredBox(
            color: const Color(0xFFF1F0F1),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Transform.translate(
                    offset: offset,
                    child: const CustomPaint(painter: _MapPreviewPainter()),
                  ),
                ),
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ],
            ),
          );
        }

        final tileSize = math.max(
          constraints.maxWidth / 3.2,
          constraints.maxHeight / 5.4,
        );
        final offsetX =
            constraints.maxWidth / 2 -
            (centerX - originX) * tileSize +
            offset.dx;
        final offsetY =
            constraints.maxHeight * 0.46 -
            (centerY - originY) * tileSize +
            offset.dy;

        return ColoredBox(
          color: const Color(0xFFF1F0F1),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (var row = 0; row < 7; row++)
                for (var col = 0; col < 5; col)
                  Positioned(
                    left: offsetX + col * tileSize,
                    top: offsetY + row * tileSize,
                    width: tileSize,
                    height: tileSize,
                    child: Image.network(
                      'https://tile.openstreetmap.org/$zoom/${originX + col}/${originY + row}.png',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) {
                        return const CustomPaint(painter: _MapPreviewPainter());
                      },
                    ),
                  ),
              Positioned.fill(
                child: ColoredBox(color: Colors.white.withValues(alpha: 0.18)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Stylized offline fallback: city blocks + roads.
class _MapPreviewPainter extends CustomPainter {
  const _MapPreviewPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFF1F0F1);
    canvas.drawRect(Offset.zero & size, paint);

    final blocks = [
      Rect.fromLTWH(size.width * 0.02, size.height * 0.08, 120, 180),
      Rect.fromLTWH(size.width * 0.28, size.height * 0.03, 160, 150),
      Rect.fromLTWH(size.width * 0.64, size.height * 0.08, 132, 162),
      Rect.fromLTWH(size.width * 0.1, size.height * 0.36, 154, 108),
      Rect.fromLTWH(size.width * 0.58, size.height * 0.36, 156, 116),
      Rect.fromLTWH(size.width * 0.04, size.height * 0.68, 140, 136),
      Rect.fromLTWH(size.width * 0.62, size.height * 0.72, 126, 120),
      Rect.fromLTWH(size.width * 0.28, size.height * 0.58, 126, 150),
    ];

    for (final rect in blocks) {
      paint.color = const Color(0xFFE3E1E3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFD2CDD1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(10), const Radius.circular(4)),
        paint,
      );
      paint.style = PaintingStyle.fill;
    }

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final road = Path()
      ..moveTo(-20, size.height * 0.2)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.28,
        size.width * 0.34,
        size.height * 0.34,
        size.width * 0.52,
        size.height * 0.28,
      )
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.22,
        size.width * 0.78,
        size.height * 0.52,
        size.width + 20,
        size.height * 0.5,
      );
    canvas.drawPath(road, roadPaint);

    roadPaint
      ..color = const Color(0xFFC9C1C7)
      ..strokeWidth = 4;
    canvas.drawPath(road, roadPaint);

    final crossRoad = Path()
      ..moveTo(size.width * 0.24, size.height + 20)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.72,
        size.width * 0.54,
        size.height * 0.62,
        size.width * 0.58,
        -20,
      );
    roadPaint
      ..color = Colors.white
      ..strokeWidth = 26;
    canvas.drawPath(crossRoad, roadPaint);

    roadPaint
      ..color = const Color(0xFFC9C1C7)
      ..strokeWidth = 4;
    canvas.drawPath(crossRoad, roadPaint);

    final sideRoads = [
      Path()
        ..moveTo(-20, size.height * 0.42)
        ..lineTo(size.width + 20, size.height * 0.28),
      Path()
        ..moveTo(-20, size.height * 0.68)
        ..lineTo(size.width + 20, size.height * 0.62),
      Path()
        ..moveTo(size.width * 0.14, -20)
        ..lineTo(size.width * 0.38, size.height + 20),
      Path()
        ..moveTo(size.width * 0.84, -20)
        ..lineTo(size.width * 0.72, size.height + 20),
    ];

    for (final path in sideRoads) {
      roadPaint
        ..color = Colors.white
        ..strokeWidth = 15;
      canvas.drawPath(path, roadPaint);
      roadPaint
        ..color = const Color(0xFFD1CCD0)
        ..strokeWidth = 3;
      canvas.drawPath(path, roadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Teardrop pin marker for a map destination.
class MapPinMarker extends StatelessWidget {
  const MapPinMarker({
    super.key,
    this.color = AppColorsDefault.brandForest,
    this.size = 44,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.25),
      painter: _PinPainter(color: color),
    );
  }
}

class _PinPainter extends CustomPainter {
  const _PinPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    final radius = size.width * 0.36;

    final pinPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..moveTo(center.dx - radius * 0.72, center.dy + radius * 0.55)
      ..lineTo(center.dx, size.height)
      ..lineTo(center.dx + radius * 0.72, center.dy + radius * 0.55)
      ..close();

    canvas.drawPath(
      pinPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(center, radius * 0.42, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Default accent holder so this file has no core import
/// cycle (AppColors lives in core/theme).
class AppColorsDefault {
  AppColorsDefault._();
  static const brandForest = Color(0xFF0D230D);
}
