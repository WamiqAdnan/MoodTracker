import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mood_tracker/core/models/mood_entry.dart';
import 'package:mood_tracker/features/mood/painters/timeline_face_painter.dart';

class TimelineStrip extends StatelessWidget {
  const TimelineStrip({
    super.key,
    required this.entries,
    required this.onEntryTap,
    this.animatingId,
  });

  final List<MoodEntry> entries;
  final String? animatingId;
  final void Function(String id) onEntryTap;

  static const double _faceSize = 36.0;
  static const double _leftPad = 28.0;
  static const double _rightPad = 32.0;
  static const double _bottomPad = 20.0;
  // Half the face size so faces on the top/bottom edges aren't clipped
  static const double _topPad = _faceSize / 2 + 4;

  @override
  Widget build(BuildContext context) {
    final displayed = entries.take(7).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final pts = _calcPoints(displayed, w, h);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Graph layer (no dots — faces replace them)
            CustomPaint(
              size: Size(w, h),
              painter: _MoodGraphPainter(
                entries: displayed,
                points: pts,
                topPad: _topPad,
                bottomPad: _bottomPad,
                leftPad: _leftPad,
                rightPad: _rightPad,
              ),
            ),

            // X-axis date labels
            ..._xLabels(displayed, pts, h),

            // Face icons centered on each data point.
            // The Container punches a solid circle over the line so it
            // doesn't bleed through the semi-transparent face fill.
            for (var i = 0; i < pts.length; i++)
              Positioned(
                left: pts[i].dx - _faceSize / 2,
                top: pts[i].dy - _faceSize / 2,
                child: Container(
                  width: _faceSize,
                  height: _faceSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1A1830),
                  ),
                  child: _FaceIcon(
                    key: ValueKey(displayed[i].id),
                    entry: displayed[i],
                    size: _faceSize,
                    isAnimating: animatingId == displayed[i].id,
                    onTap: () => onEntryTap(displayed[i].id),
                  ),
                ),
              ),

            if (displayed.isEmpty)
              const Center(
                child: Text(
                  'tap a mood to see your graph',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8B8FA8)),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Offset> _calcPoints(List<MoodEntry> entries, double w, double h) {
    if (entries.isEmpty) return [];
    final graphLeft = _leftPad;
    final graphRight = w - _rightPad;
    final graphTop = _topPad;
    final graphBottom = h - _bottomPad;
    final graphW = graphRight - graphLeft;
    final graphH = graphBottom - graphTop;

    return List.generate(entries.length, (i) {
      final xFrac = entries.length == 1 ? 0.5 : i / (entries.length - 1);
      final x = graphLeft + xFrac * graphW;
      final val = entries[i].moodType.graphValue; // 1–5
      final yFrac = 1.0 - (val - 1) / 4.0; // 5→top, 1→bottom
      final y = graphTop + yFrac * graphH;
      return Offset(x, y);
    });
  }

  List<Widget> _xLabels(List<MoodEntry> displayed, List<Offset> pts, double h) {
    final fmt = DateFormat('d MMM');
    final top = h - _bottomPad + 4;
    return List.generate(pts.length, (i) {
      final label = fmt.format(displayed[i].timestamp);
      return Positioned(
        left: (pts[i].dx - 22).clamp(0.0, double.infinity),
        top: top,
        child: SizedBox(
          width: 44,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8, color: Color(0xFF8B8FA8)),
          ),
        ),
      );
    });
  }
}

// ── Graph painter ─────────────────────────────────────────────────────────────

class _MoodGraphPainter extends CustomPainter {
  const _MoodGraphPainter({
    required this.entries,
    required this.points,
    required this.topPad,
    required this.bottomPad,
    required this.leftPad,
    required this.rightPad,
  });

  final List<MoodEntry> entries;
  final List<Offset> points;
  final double topPad;
  final double bottomPad;
  final double leftPad;
  final double rightPad;

  static const _lineColor = Color(0xFF7A9BAD);
  static const _axisColor = Color(0xFF2A2740);

  @override
  void paint(Canvas canvas, Size size) {
    final graphTop = topPad;
    final graphBottom = size.height - bottomPad;
    final graphLeft = leftPad;
    final graphRight = size.width - rightPad;
    final graphH = graphBottom - graphTop;

    _drawGrid(canvas, graphLeft, graphTop, graphRight, graphBottom, graphH);
    _drawAxes(canvas, graphLeft, graphRight, graphTop, graphBottom);

    if (points.isEmpty) return;

    _drawShade(canvas, points, graphBottom);
    _drawLine(canvas, points);
    // No dots — faces sit on the line instead
  }

  void _drawAxes(
    Canvas canvas,
    double left,
    double right,
    double top,
    double bottom,
  ) {
    final p = Paint()
      ..color = _axisColor
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(left, top - 4), Offset(left, bottom), p);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), p);
  }

  void _drawGrid(
    Canvas canvas,
    double left,
    double top,
    double right,
    double bottom,
    double h,
  ) {
    final tick = Paint()
      ..color = _axisColor
      ..strokeWidth = 1.0;
    final gridLine = Paint()
      ..color = _axisColor.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    for (int v = 1; v <= 5; v++) {
      final yFrac = 1.0 - (v - 1) / 4.0;
      final y = top + yFrac * h;
      canvas.drawLine(Offset(left - 3, y), Offset(left, y), tick);
      canvas.drawLine(Offset(left, y), Offset(right, y), gridLine);
    }
  }

  void _drawShade(Canvas canvas, List<Offset> pts, double bottom) {
    final smooth = _smoothPath(pts);
    smooth.lineTo(pts.last.dx, bottom);
    smooth.lineTo(pts.first.dx, bottom);
    smooth.close();
    canvas.drawPath(
      smooth,
      Paint()
        ..color = _lineColor.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawLine(Canvas canvas, List<Offset> pts) {
    canvas.drawPath(
      _smoothPath(pts),
      Paint()
        ..color = _lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _smoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    if (pts.length == 1) return path;
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i > 0 ? i - 1 : i];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[i < pts.length - 2 ? i + 2 : i + 1];
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_MoodGraphPainter old) =>
      old.entries != entries || old.points != points;
}

// ── Face icon ─────────────────────────────────────────────────────────────────

class _FaceIcon extends StatefulWidget {
  const _FaceIcon({
    super.key,
    required this.entry,
    required this.size,
    required this.onTap,
    this.isAnimating = false,
  });

  final MoodEntry entry;
  final double size;
  final VoidCallback onTap;
  final bool isAnimating;

  @override
  State<_FaceIcon> createState() => _FaceIconState();
}

class _FaceIconState extends State<_FaceIcon> with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_ctrl);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: widget.entry.moodType.pulseDuration,
    );
    _pulseAnim = CurvedAnimation(
      parent: _pulseCtrl,
      curve: widget.entry.moodType.pulseCurve,
    );
  }

  @override
  void didUpdateWidget(_FaceIcon old) {
    super.didUpdateWidget(old);
    if (widget.isAnimating && !old.isAnimating) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onHover(bool hovered) {
    if (hovered) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, _) => CustomPaint(
              size: Size(widget.size, widget.size),
              painter: TimelineFacePainter(
                mood: widget.entry.moodType,
                accentColor: widget.entry.moodType.color,
                expressionPulse: _pulseAnim.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
