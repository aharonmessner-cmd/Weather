import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/models/weather_condition.dart';

/// Custom-drawn condition glyphs, replacing the Material-icon placeholder
/// used through Stage 2. Recreated in spirit from hand-drawn reference
/// artwork, but deliberately kept small and secondary wherever they're
/// used — condition indicators next to data, not hero illustrations. Each
/// is a small self-contained [CustomPainter], which also makes them cheap
/// to animate individually later (Stage 7) without restructuring anything
/// that already places a [WeatherGlyph].
class WeatherGlyph extends StatelessWidget {
  const WeatherGlyph({
    super.key,
    required this.condition,
    this.isDaytime = true,
    this.size = 22,
    this.color,
  });

  final WeatherCondition condition;
  final bool isDaytime;
  final double size;

  /// Overrides the glyph's natural coloring (sun gold, moon silver, cloud
  /// white/gray) with a single flat color — used when a glyph sits next
  /// to text that needs to match it exactly (e.g. the hero's condition
  /// row).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _painterFor(condition, isDaytime, color),
      ),
    );
  }

  CustomPainter _painterFor(WeatherCondition condition, bool isDaytime, Color? color) {
    switch (condition) {
      case WeatherCondition.clearSky:
      case WeatherCondition.hot:
        return isDaytime ? _SunPainter(color: color) : _MoonPainter(color: color);
      case WeatherCondition.mostlyClear:
        return isDaytime ? _SunPainter(color: color, rays: false) : _MoonPainter(color: color);
      case WeatherCondition.partlyCloudy:
        return _PartlyCloudyPainter(isDaytime: isDaytime, color: color);
      case WeatherCondition.mostlyCloudy:
      case WeatherCondition.cold:
        return _CloudPainter(color: color, layers: 2);
      case WeatherCondition.overcast:
        return _CloudPainter(color: color, layers: 3);
      case WeatherCondition.fog:
      case WeatherCondition.hazy:
      case WeatherCondition.smoke:
      case WeatherCondition.dust:
        return _FogPainter(color: color);
      case WeatherCondition.drizzle:
        return _RainPainter(color: color, dropCount: 2, light: true);
      case WeatherCondition.rain:
      case WeatherCondition.rainShowers:
        return _RainPainter(color: color, dropCount: 3, light: false);
      case WeatherCondition.snow:
      case WeatherCondition.snowShowers:
        return _SnowPainter(color: color);
      case WeatherCondition.sleet:
      case WeatherCondition.freezingRain:
      case WeatherCondition.wintryMix:
        return _WintryMixPainter(color: color);
      case WeatherCondition.thunderstorms:
        return _ThunderstormPainter(color: color);
      case WeatherCondition.windy:
        return _WindPainter(color: color);
      case WeatherCondition.tornado:
      case WeatherCondition.tropicalStorm:
      case WeatherCondition.hurricane:
        return _SwirlPainter(color: color);
      case WeatherCondition.unknown:
        return _UnknownPainter(color: color);
    }
  }
}

const _cloudColor = Color(0xFFEDEFF5);
const _cloudColorDeep = Color(0xFFC9CEDC);
const _sunGold = Color(0xFFFFC94A);
const _sunCore = Color(0xFFFFE08A);
const _moonColor = Color(0xFFEAEFFF);
const _rainColor = Color(0xFF6FB8DD);
const _snowColor = Color(0xFFF3F7FF);
const _boltColor = Color(0xFFFFD75E);

void _drawCloudPuffs(Canvas canvas, Size size, Color color, {double yOffset = 0}) {
  final w = size.width;
  final h = size.height;
  final paint = Paint()..color = color;
  final cy = h * (0.62 + yOffset);
  canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.55, cy), width: w * 0.62, height: h * 0.42), paint);
  canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.32, cy + h * 0.06), width: w * 0.48, height: h * 0.34), paint);
  canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.46, cy - h * 0.14), width: w * 0.4, height: h * 0.32), paint);
}

class _SunPainter extends CustomPainter {
  _SunPainter({this.color, this.rays = true});
  final Color? color;
  final bool rays;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.28;
    if (rays) {
      final rayPaint = Paint()
        ..color = (color ?? _sunGold).withValues(alpha: 0.85)
        ..strokeWidth = size.shortestSide * 0.06
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final inner = center + Offset(math.cos(angle), math.sin(angle)) * (radius * 1.35);
        final outer = center + Offset(math.cos(angle), math.sin(angle)) * (radius * 1.85);
        canvas.drawLine(inner, outer, rayPaint);
      }
    }
    final corePaint = Paint()
      ..shader = RadialGradient(colors: [color ?? _sunCore, color ?? _sunGold])
          .createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, corePaint);
  }

  @override
  bool shouldRepaint(covariant _SunPainter oldDelegate) => false;
}

class _MoonPainter extends CustomPainter {
  _MoonPainter({this.color});
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide * 0.3;
    final center = Offset(size.width / 2, size.height / 2);
    final basePaint = Paint()..color = color ?? _moonColor;
    final cutoutPaint = Paint()..blendMode = BlendMode.srcOut;
    // saveLayer + srcOut punches the cutout circle out of the base disc,
    // producing the crescent silhouette.
    canvas.saveLayer(Rect.fromCircle(center: center, radius: radius + 2), Paint());
    canvas.drawCircle(center, radius, basePaint);
    canvas.drawCircle(center + Offset(radius * 0.55, -radius * 0.2), radius * 0.85, cutoutPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) => false;
}

class _PartlyCloudyPainter extends CustomPainter {
  _PartlyCloudyPainter({required this.isDaytime, this.color});
  final bool isDaytime;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * 0.34, size.height * 0.36);
    final sunRadius = size.shortestSide * 0.2;
    final sunPaint = Paint()..color = color ?? (isDaytime ? _sunGold : _moonColor);
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);
    _drawCloudPuffs(canvas, size, color ?? _cloudColor, yOffset: 0.08);
  }

  @override
  bool shouldRepaint(covariant _PartlyCloudyPainter oldDelegate) => false;
}

class _CloudPainter extends CustomPainter {
  _CloudPainter({this.color, this.layers = 2});
  final Color? color;
  final int layers;

  @override
  void paint(Canvas canvas, Size size) {
    _drawCloudPuffs(canvas, size, (color ?? _cloudColor).withValues(alpha: layers >= 3 ? 0.75 : 0.9));
    if (layers >= 2) {
      final paint = Paint()..color = color ?? _cloudColorDeep;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.62, size.height * 0.42), width: size.width * 0.4, height: size.height * 0.28),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) => false;
}

class _FogPainter extends CustomPainter {
  _FogPainter({this.color});
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (color ?? _cloudColor).withValues(alpha: 0.85)
      ..strokeWidth = size.height * 0.09
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.36 + i * 0.2);
      final inset = i.isOdd ? size.width * 0.18 : size.width * 0.08;
      canvas.drawLine(Offset(inset, y), Offset(size.width - inset, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FogPainter oldDelegate) => false;
}

class _RainPainter extends CustomPainter {
  _RainPainter({this.color, this.dropCount = 3, this.light = false});
  final Color? color;
  final int dropCount;
  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    _drawCloudPuffs(canvas, size, (color ?? _cloudColor).withValues(alpha: 0.9), yOffset: -0.08);
    final paint = Paint()
      ..color = color ?? _rainColor
      ..strokeWidth = size.width * (light ? 0.05 : 0.07)
      ..strokeCap = StrokeCap.round;
    final startX = size.width * 0.28;
    final spacing = size.width * 0.22;
    for (var i = 0; i < dropCount; i++) {
      final x = startX + spacing * i;
      final y0 = size.height * 0.78;
      canvas.drawLine(Offset(x, y0), Offset(x - size.width * 0.06, y0 + size.height * 0.16), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => false;
}

class _SnowPainter extends CustomPainter {
  _SnowPainter({this.color});
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    _drawCloudPuffs(canvas, size, (color ?? _cloudColor).withValues(alpha: 0.9), yOffset: -0.1);
    final paint = Paint()..color = color ?? _snowColor;
    final startX = size.width * 0.3;
    final spacing = size.width * 0.22;
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(startX + spacing * i, size.height * 0.84), size.width * 0.045, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) => false;
}

class _WintryMixPainter extends CustomPainter {
  _WintryMixPainter({this.color});
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    _drawCloudPuffs(canvas, size, (color ?? _cloudColor).withValues(alpha: 0.9), yOffset: -0.1);
    final dotPaint = Paint()..color = color ?? _snowColor;
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.84), size.width * 0.045, dotPaint);
    final linePaint = Paint()
      ..color = color ?? _rainColor
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * 0.76),
      Offset(size.width * 0.56, size.height * 0.92),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WintryMixPainter oldDelegate) => false;
}

class _ThunderstormPainter extends CustomPainter {
  _ThunderstormPainter({this.color});
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    _drawCloudPuffs(canvas, size, (color ?? _cloudColorDeep).withValues(alpha: 0.95), yOffset: -0.14);
    final boltPaint = Paint()..color = color ?? _boltColor;
    final path = Path()
      ..moveTo(size.width * 0.55, size.height * 0.56)
      ..lineTo(size.width * 0.4, size.height * 0.8)
      ..lineTo(size.width * 0.5, size.height * 0.8)
      ..lineTo(size.width * 0.38, size.height * 1.0)
      ..lineTo(size.width * 0.64, size.height * 0.72)
      ..lineTo(size.width * 0.52, size.height * 0.72)
      ..close();
    canvas.drawPath(path, boltPaint);
  }

  @override
  bool shouldRepaint(covariant _ThunderstormPainter oldDelegate) => false;
}

class _WindPainter extends CustomPainter {
  _WindPainter({this.color});
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? _cloudColorDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.09
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.32 + i * 0.22);
      final path = Path()
        ..moveTo(size.width * 0.12, y)
        ..lineTo(size.width * (0.7 - i * 0.08), y)
        ..arcToPoint(Offset(size.width * (0.82 - i * 0.08), y - size.height * 0.09), radius: Radius.circular(size.height * 0.09));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WindPainter oldDelegate) => false;
}

class _SwirlPainter extends CustomPainter {
  _SwirlPainter({this.color});
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? _cloudColorDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.09
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 3; i++) {
      final radius = size.shortestSide * (0.42 - i * 0.12);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi * 1.5, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SwirlPainter oldDelegate) => false;
}

class _UnknownPainter extends CustomPainter {
  _UnknownPainter({this.color});
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (color ?? _cloudColorDeep).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.08;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.shortestSide * 0.32, paint);
  }

  @override
  bool shouldRepaint(covariant _UnknownPainter oldDelegate) => false;
}
