import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const KaleidoscopeApp());
}

class KaleidoscopeApp extends StatelessWidget {
  const KaleidoscopeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kaleidoscope Studio',
      theme: ThemeData.dark(useMaterial3: true),
      home: const KaleidoscopeScreen(),
    );
  }
}

class MandalaStroke {
  final List<Offset> normalizedPoints; // Орталықтан (-1.0 .. 1.0)
  final Color color;
  final double strokeWidth;
  final int symmetrySegments;
  final bool mirrorReflection;

  const MandalaStroke({
    required this.normalizedPoints,
    required this.color,
    required this.strokeWidth,
    required this.symmetrySegments,
    required this.mirrorReflection,
  });
}

class KaleidoscopeScreen extends StatefulWidget {
  const KaleidoscopeScreen({super.key});

  @override
  State<KaleidoscopeScreen> createState() => _KaleidoscopeScreenState();
}

class _KaleidoscopeScreenState extends State<KaleidoscopeScreen> {
  final List<MandalaStroke> _strokes = [];
  List<Offset> _currentPoints = [];

  int _symmetrySegments = 12;
  bool _mirrorReflection = true;
  double _strokeWidth = 2.6;
  int _selectedColorIndex = 0;
  bool _showGuides = true;

  final List<Color> _palette = const [
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.amberAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.white,
  ];

  Offset _toNormalized(Offset localPos, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(cx, cy);
    return Offset((localPos.dx - cx) / radius, (localPos.dy - cy) / radius);
  }

  void _startStroke(Offset localPos, Size size) {
    setState(() {
      _currentPoints = [_toNormalized(localPos, size)];
    });
  }

  void _appendStroke(Offset localPos, Size size) {
    setState(() {
      _currentPoints.add(_toNormalized(localPos, size));
    });
  }

  void _endStroke() {
    if (_currentPoints.isNotEmpty) {
      setState(() {
        _strokes.add(
          MandalaStroke(
            normalizedPoints: List<Offset>.from(_currentPoints),
            color: _palette[_selectedColorIndex],
            strokeWidth: _strokeWidth,
            symmetrySegments: _symmetrySegments,
            mirrorReflection: _mirrorReflection,
          ),
        );
        _currentPoints = [];
      });
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() => _strokes.removeLast());
    }
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentPoints = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070910),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Kaleidoscope Studio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => setState(() => _showGuides = !_showGuides),
            icon: Icon(_showGuides ? Icons.grid_on : Icons.grid_off),
            tooltip: 'Toggle Symmetry Guides',
          ),
          IconButton(
            onPressed: _strokes.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
          ),
          IconButton(
            onPressed: _strokes.isEmpty ? null : _clearCanvas,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final allStrokes = <MandalaStroke>[
                  ..._strokes,
                  if (_currentPoints.isNotEmpty)
                    MandalaStroke(
                      normalizedPoints: _currentPoints,
                      color: _palette[_selectedColorIndex],
                      strokeWidth: _strokeWidth,
                      symmetrySegments: _symmetrySegments,
                      mirrorReflection: _mirrorReflection,
                    ),
                ];

                return GestureDetector(
                  onPanStart: (d) => _startStroke(d.localPosition, size),
                  onPanUpdate: (d) => _appendStroke(d.localPosition, size),
                  onPanEnd: (_) => _endStroke(),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C101C),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _palette[_selectedColorIndex].withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CustomPaint(
                        painter: _KaleidoscopePainter(
                          strokes: allStrokes,
                          guideSegments: _symmetrySegments,
                          showGuides: _showGuides,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_palette.length, (i) {
                    final color = _palette[i];
                    final selected = i == _selectedColorIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [6, 8, 12, 16].map((seg) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('${seg}x'),
                        selected: _symmetrySegments == seg,
                        onSelected: (_) =>
                            setState(() => _symmetrySegments = seg),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Mirror'),
                      selected: _mirrorReflection,
                      onSelected: (v) => setState(() => _mirrorReflection = v),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.brush, size: 18, color: Colors.white70),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 1.2,
                        max: 7.0,
                        activeColor: _palette[_selectedColorIndex],
                        onChanged: (v) => setState(() => _strokeWidth = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KaleidoscopePainter extends CustomPainter {
  final List<MandalaStroke> strokes;
  final int guideSegments;
  final bool showGuides;

  _KaleidoscopePainter({
    required this.strokes,
    required this.guideSegments,
    required this.showGuides,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(center.dx, center.dy);

    if (showGuides) {
      final guidePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1;
      for (int i = 0; i < guideSegments; i++) {
        final angle = (2 * pi * i) / guideSegments;
        final end = Offset(
          center.dx + radius * 1.4 * cos(angle),
          center.dy + radius * 1.4 * sin(angle),
        );
        canvas.drawLine(center, end, guidePaint);
      }
      canvas.drawCircle(
        center,
        radius * 0.5,
        guidePaint..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        center,
        radius * 0.9,
        guidePaint..style = PaintingStyle.stroke,
      );
    }

    for (final stroke in strokes) {
      if (stroke.normalizedPoints.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final stepAngle = (2 * pi) / stroke.symmetrySegments;

      for (int s = 0; s < stroke.symmetrySegments; s++) {
        final theta = s * stepAngle;
        _drawTransformedPath(
          canvas,
          center,
          radius,
          stroke.normalizedPoints,
          theta,
          false,
          paint,
        );
        if (stroke.mirrorReflection) {
          _drawTransformedPath(
            canvas,
            center,
            radius,
            stroke.normalizedPoints,
            theta,
            true,
            paint,
          );
        }
      }
    }
  }

  void _drawTransformedPath(
    Canvas canvas,
    Offset center,
    double radius,
    List<Offset> points,
    double angle,
    bool mirror,
    Paint paint,
  ) {
    final cosA = cos(angle);
    final sinA = sin(angle);

    Offset transform(Offset p) {
      final px = p.dx * radius;
      final py = (mirror ? -p.dy : p.dy) * radius;
      final rx = px * cosA - py * sinA;
      final ry = px * sinA + py * cosA;
      return Offset(center.dx + rx, center.dy + ry);
    }

    if (points.length == 1) {
      canvas.drawCircle(
        transform(points.first),
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      paint.style = PaintingStyle.stroke;
      return;
    }

    final path = Path();
    final first = transform(points.first);
    path.moveTo(first.dx, first.dy);
    for (int i = 1; i < points.length; i++) {
      final pt = transform(points[i]);
      path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _KaleidoscopePainter oldDelegate) => true;
}
