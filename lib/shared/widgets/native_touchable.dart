import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class NativeTouchable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedOpacity;
  final Duration duration;
  final HitTestBehavior behavior;
  final double? minWidth;
  final double? minHeight;

  const NativeTouchable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedOpacity = 0.6,
    this.duration = const Duration(milliseconds: 100),
    this.behavior = HitTestBehavior.opaque,
    this.minWidth,
    this.minHeight,
  });

  @override
  State<NativeTouchable> createState() => _NativeTouchableState();
}

class _NativeTouchableState extends State<NativeTouchable> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap:
          widget.onTap != null
              ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
              : null,
      child: AnimatedOpacity(
        duration: widget.duration,
        opacity: _isPressed ? widget.pressedOpacity : 1.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minWidth ?? 0,
            minHeight: widget.minHeight ?? 0,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
