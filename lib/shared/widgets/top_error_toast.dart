import 'package:flutter/material.dart';

void showTopErrorToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final theme = Theme.of(context);

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder:
        (context) => Positioned(
          top:
              MediaQuery.of(context).padding.top +
              60, // AppBar height + padding
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.onError),
                    const SizedBox(width: 12),
                    Expanded(
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
  );

  overlay.insert(overlayEntry);

  Future.delayed(const Duration(seconds: 3), () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}
