import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Full-screen signature drawing pad with colors and undo
class SignaturePadScreen extends StatefulWidget {
  const SignaturePadScreen({super.key});

  @override
  State<SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _SignaturePadScreenState extends State<SignaturePadScreen> {
  final List<DrawnStroke> _strokes = [];
  final List<DrawnStroke> _undoneStrokes = []; // For redo
  List<Offset> _currentPoints = [];
  
  // Drawing settings
  Color _strokeColor = Colors.black;
  double _strokeWidth = 3.0;
  
  // Available colors
  final List<Color> _availableColors = [
    Colors.black,
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.brown,
  ];
  
  // Available stroke widths
  final List<double> _strokeWidths = [2.0, 3.0, 5.0, 8.0];

  bool get _hasSignature => _strokes.isNotEmpty || _currentPoints.isNotEmpty;
  bool get _canUndo => _strokes.isNotEmpty;
  bool get _canRedo => _undoneStrokes.isNotEmpty;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentPoints = [details.localPosition];
      _undoneStrokes.clear(); // Clear redo stack on new stroke
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPoints.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPoints.isNotEmpty) {
      setState(() {
        _strokes.add(DrawnStroke(
          points: List.from(_currentPoints),
          color: _strokeColor,
          strokeWidth: _strokeWidth,
        ));
        _currentPoints = [];
      });
    }
  }

  void _undo() {
    if (_canUndo) {
      setState(() {
        _undoneStrokes.add(_strokes.removeLast());
      });
    }
  }

  void _redo() {
    if (_canRedo) {
      setState(() {
        _strokes.add(_undoneStrokes.removeLast());
      });
    }
  }

  void _clear() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Signature?'),
        content: const Text('This will clear your entire signature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _strokes.clear();
                _undoneStrokes.clear();
                _currentPoints = [];
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndReturn() async {
    if (!_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw your signature first')),
      );
      return;
    }

    // Export signature as PNG
    final Uint8List? signatureBytes = await _exportSignature();
    if (signatureBytes != null && mounted) {
      Navigator.pop(context, signatureBytes);
    }
  }

  Future<Uint8List?> _exportSignature() async {
    try {
      // Calculate signature bounds
      final bounds = _getSignatureBounds();
      if (bounds == null) return null;

      // Add padding
      const padding = 20.0;
      final width = (bounds.width + padding * 2).toInt().clamp(100, 800);
      final height = (bounds.height + padding * 2).toInt().clamp(50, 300);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = Colors.white,
      );

      // Calculate offset to center signature
      final offsetX = padding - bounds.left;
      final offsetY = padding - bounds.top;

      // Draw all strokes
      for (final stroke in _strokes) {
        if (stroke.points.length < 2) continue;

        final paint = Paint()
          ..color = stroke.color
          ..strokeWidth = stroke.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        final path = Path();
        path.moveTo(
          stroke.points[0].dx + offsetX,
          stroke.points[0].dy + offsetY,
        );

        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(
            stroke.points[i].dx + offsetX,
            stroke.points[i].dy + offsetY,
          );
        }
        canvas.drawPath(path, paint);
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(width, height);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error exporting signature: $e');
      return null;
    }
  }

  Rect? _getSignatureBounds() {
    if (_strokes.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final stroke in _strokes) {
      for (final point in stroke.points) {
        if (point.dx < minX) minX = point.dx;
        if (point.dy < minY) minY = point.dy;
        if (point.dx > maxX) maxX = point.dx;
        if (point.dy > maxY) maxY = point.dy;
      }
    }

    if (minX == double.infinity) return null;
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Draw Signature'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _hasSignature ? _saveAndReturn : null,
            icon: const Icon(Icons.check),
            label: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                // Undo button
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: _canUndo ? _undo : null,
                  tooltip: 'Undo',
                ),
                // Redo button
                IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: _canRedo ? _redo : null,
                  tooltip: 'Redo',
                ),
                const VerticalDivider(),
                // Clear button
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _hasSignature ? _clear : null,
                  tooltip: 'Clear All',
                ),
                const Spacer(),
                // Stroke width selector
                PopupMenuButton<double>(
                  icon: Icon(Icons.line_weight, size: _strokeWidth * 4),
                  tooltip: 'Stroke Width',
                  onSelected: (width) {
                    setState(() => _strokeWidth = width);
                  },
                  itemBuilder: (context) => _strokeWidths.map((width) {
                    return PopupMenuItem(
                      value: width,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: width,
                            color: _strokeColor,
                          ),
                          const SizedBox(width: 12),
                          Text('${width.toInt()}px'),
                          if (_strokeWidth == width)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(Icons.check, size: 18),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Color picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _availableColors.map((color) {
                final isSelected = _strokeColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _strokeColor = color),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colorScheme.primary : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: color == Colors.black ? Colors.white : Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Drawing canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Drawing area
                    GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _SignaturePainter(
                          strokes: _strokes,
                          currentPoints: _currentPoints,
                          currentColor: _strokeColor,
                          currentStrokeWidth: _strokeWidth,
                        ),
                      ),
                    ),

                    // Placeholder when empty
                    if (!_hasSignature)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.draw_outlined,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Draw your signature here',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Signature line
                    Positioned(
                      left: 40,
                      right: 40,
                      bottom: 60,
                      child: Container(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    Positioned(
                      left: 40,
                      bottom: 40,
                      child: Text(
                        'Sign above the line',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom hint
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              'Use your finger or stylus to sign',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Represents a drawn stroke with its properties
class DrawnStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawnStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

/// Custom painter for rendering signature strokes
class _SignaturePainter extends CustomPainter {
  final List<DrawnStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentStrokeWidth;

  _SignaturePainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(stroke.points[0].dx, stroke.points[0].dy);

      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw current stroke
    if (currentPoints.length >= 2) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(currentPoints[0].dx, currentPoints[0].dy);

      for (int i = 1; i < currentPoints.length; i++) {
        path.lineTo(currentPoints[i].dx, currentPoints[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
