import 'package:flutter/material.dart';

// Constants
const double _kToastTopMargin = 10.0;
const double _kToastBorderRadius = 30.0;
const Duration _kToastDuration = Duration(milliseconds: 300);
const Duration _kToastDisplayDuration = Duration(seconds: 3);

// Singleton to manage the current overlay entry
OverlayEntry? _currentOverlayEntry;

void showTopErrorToast(BuildContext context, String message) {
  // Remove existing toast if any
  _currentOverlayEntry?.remove();
  _currentOverlayEntry = null;

  final overlay = Overlay.of(context);
  final theme = Theme.of(context);

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder:
        (context) => Positioned(
          top: MediaQuery.of(context).padding.top + _kToastTopMargin,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Semantics(
                liveRegion: true,
                label: 'エラー: $message',
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: _kToastDuration,
                  curve: Curves.easeOutCubic, // UIX-003: Better animation curve
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, -20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(_kToastBorderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.onError,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onError,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
  );

  _currentOverlayEntry = overlayEntry;
  overlay.insert(overlayEntry);

  Future.delayed(_kToastDisplayDuration, () {
    // Only remove if it's still the current entry
    if (_currentOverlayEntry == overlayEntry) {
      overlayEntry.remove();
      _currentOverlayEntry = null;
    }
  });
}
