import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A widget that allows users to draw their signature with finger/stylus
class SignatureCanvas extends StatefulWidget {
  const SignatureCanvas({
    super.key,
    this.strokeColor = Colors.black,
    this.strokeWidth = 3.0,
    this.backgroundColor = Colors.white,
    this.height = 200,
    this.onSignatureChanged,
  });

  final Color strokeColor;
  final double strokeWidth;
  final Color backgroundColor;
  final double height;
  final VoidCallback? onSignatureChanged;

  @override
  State<SignatureCanvas> createState() => SignatureCanvasState();
}

class SignatureCanvasState extends State<SignatureCanvas> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _hasSignature = false;

  /// Clear the signature canvas
  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _hasSignature = false;
    });
    widget.onSignatureChanged?.call();
  }

  /// Check if canvas has any signature
  bool get hasSignature => _hasSignature;

  /// Check if canvas is empty
  bool get isEmpty => _strokes.isEmpty && _currentStroke.isEmpty;

  /// Export signature as PNG bytes
  Future<Uint8List?> toImage({int width = 400, int height = 150}) async {
    if (isEmpty) return null;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = Colors.white,
      );

      // Calculate scale to fit signature in the given dimensions
      final bounds = _getSignatureBounds();
      if (bounds == null) return null;

      final signatureWidth = bounds.width;
      final signatureHeight = bounds.height;
      
      // Add padding
      const padding = 20.0;
      final scaleX = (width - padding * 2) / signatureWidth;
      final scaleY = (height - padding * 2) / signatureHeight;
      final scale = scaleX < scaleY ? scaleX : scaleY;

      // Center the signature
      final offsetX = (width - signatureWidth * scale) / 2 - bounds.left * scale;
      final offsetY = (height - signatureHeight * scale) / 2 - bounds.top * scale;

      // Draw signature with scaling
      final paint = Paint()
        ..color = widget.strokeColor
        ..strokeWidth = widget.strokeWidth * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (final stroke in _strokes) {
        if (stroke.length < 2) continue;
        
        final path = Path();
        path.moveTo(
          stroke[0].dx * scale + offsetX,
          stroke[0].dy * scale + offsetY,
        );
        
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(
            stroke[i].dx * scale + offsetX,
            stroke[i].dy * scale + offsetY,
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

  /// Get the bounding box of the signature
  Rect? _getSignatureBounds() {
    if (_strokes.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final stroke in _strokes) {
      for (final point in stroke) {
        if (point.dx < minX) minX = point.dx;
        if (point.dy < minY) minY = point.dy;
        if (point.dx > maxX) maxX = point.dx;
        if (point.dy > maxY) maxY = point.dy;
      }
    }

    if (minX == double.infinity) return null;
    
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
      _hasSignature = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      if (_currentStroke.isNotEmpty) {
        _strokes.add(List.from(_currentStroke));
        _currentStroke = [];
      }
    });
    widget.onSignatureChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
                  currentStroke: _currentStroke,
                  strokeColor: widget.strokeColor,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
            ),
            
            // Signature line placeholder
            if (isEmpty)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.draw,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Draw your signature here',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Signature line
            Positioned(
              left: 20,
              right: 20,
              bottom: 30,
              child: Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
            ),
            
            // "Sign here" label
            Positioned(
              left: 20,
              bottom: 10,
              child: Text(
                'Sign above the line',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for drawing signature strokes
class _SignaturePainter extends CustomPainter {
  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.strokeColor,
    required this.strokeWidth,
  });

  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color strokeColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      
      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);
      
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw current stroke
    if (currentStroke.length >= 2) {
      final path = Path();
      path.moveTo(currentStroke[0].dx, currentStroke[0].dy);
      
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return true; // Always repaint for smooth drawing
  }
}
