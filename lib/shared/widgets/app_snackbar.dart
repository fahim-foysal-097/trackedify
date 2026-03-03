import 'package:flutter/material.dart';

/// Centralised SnackBar helpers. Every call site should use these
/// instead of building raw [SnackBar] widgets inline.
///
/// All methods internally call [ScaffoldMessenger] so the call site
/// only needs one line, e.g.:
///
/// ```dart
/// if (!mounted) return;
/// AppSnackBar.showError(context, 'Something went wrong');
/// ```
class AppSnackBar {
  AppSnackBar._();

  // -- Success -----------------------------------------------------------------

  /// Show a success (primary-coloured) floating SnackBar.
  static void showSuccess(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_outline,
    Duration duration = const Duration(seconds: 3),
  }) {
    final cs = Theme.of(context).colorScheme;
    _show(
      context,
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.primary,
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: cs.onPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: cs.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  // -- Error --------------------------------------------------------------------

  /// Show an error-coloured floating SnackBar.
  static void showError(
    BuildContext context,
    String message, {
    IconData icon = Icons.error_outline_rounded,
    Duration duration = const Duration(seconds: 3),
  }) {
    final cs = Theme.of(context).colorScheme;
    _show(
      context,
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.error,
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: cs.onError),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: cs.onError)),
            ),
          ],
        ),
      ),
    );
  }

  // -- Info ---------------------------------------------------------------------

  /// Show an informational floating SnackBar (uses surface/onSurface colours).
  static void showInfo(
    BuildContext context,
    String message, {
    IconData? icon,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: action,
        content: icon != null
            ? Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message)),
                ],
              )
            : Text(message),
      ),
    );
  }

  // -- With Undo ----------------------------------------------------------------

  /// Show a deletion-style error SnackBar with an UNDO action.
  static void showWithUndo(
    BuildContext context,
    String message,
    VoidCallback onUndo, {
    IconData icon = Icons.delete,
    Duration duration = const Duration(seconds: 5),
  }) {
    final cs = Theme.of(context).colorScheme;
    _show(
      context,
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.error,
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: cs.onError),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: cs.onError)),
            ),
            TextButton(
              onPressed: onUndo,
              child: Text(
                'UNDO',
                style: TextStyle(
                  color: cs.onError,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Internal -----------------------------------------------------------------

  static void _show(BuildContext context, SnackBar snackBar) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
