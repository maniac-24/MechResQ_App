// lib/utils/snackbar_helper.dart
// App-wide unified SnackBar helper with theme-aware colors and consistent UX

import 'package:flutter/material.dart';

/// Unified SnackBar helper for consistent messaging across the app
/// 
/// Usage:
/// ```dart
/// // Standard (high visibility - recommended)
/// SnackBarHelper.showSuccess(context, 'Request accepted');
/// SnackBarHelper.showError(context, 'Failed to load data');
/// 
/// // Subtle variant (optional - for low-priority messages)
/// SnackBarHelper.showSuccessSubtle(context, 'Settings saved');
/// SnackBarHelper.showInfoSubtle(context, 'Cache cleared');
/// ```
class SnackBarHelper {
  SnackBarHelper._(); // Private constructor - this is a static utility class

  // =========================================================================
  // STANDARD VARIANTS (Recommended - High Visibility)
  // Uses direct colors (secondary, error, primary, tertiary)
  // =========================================================================

  /// Show a success message (green/secondary theme color)
  /// High visibility - recommended for important confirmations
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: scheme.onSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onSecondary),
              ),
            ),
          ],
        ),
        backgroundColor: scheme.secondary,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show an error message (red/error theme color)
  /// High visibility - recommended for errors and failures
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error,
              color: scheme.onError,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onError),
              ),
            ),
          ],
        ),
        backgroundColor: scheme.error,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show an informational message (primary theme color)
  /// High visibility - recommended for important information
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info,
              color: scheme.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: scheme.primary,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a warning message (tertiary/orange theme color)
  /// High visibility - recommended for warnings
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: scheme.onTertiary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onTertiary),
              ),
            ),
          ],
        ),
        backgroundColor: scheme.tertiary,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================================
  // SUBTLE VARIANTS (Optional - Low Visibility)
  // Uses container colors (secondaryContainer, errorContainer, etc.)
  // Use for low-priority, informational messages
  // =========================================================================

  /// Show a subtle success message (muted green)
  /// Lower visibility - use for minor updates like "Settings saved"
  static void showSuccessSubtle(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: scheme.onSecondaryContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
        backgroundColor: scheme.secondaryContainer,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a subtle error message (muted red)
  /// Lower visibility - use for non-critical errors
  static void showErrorSubtle(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: scheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
        backgroundColor: scheme.errorContainer,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a subtle info message (muted blue)
  /// Lower visibility - use for background updates
  static void showInfoSubtle(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: scheme.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onPrimaryContainer),
              ),
            ),
          ],
        ),
        backgroundColor: scheme.primaryContainer,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a subtle warning message (muted orange)
  /// Lower visibility - use for non-urgent warnings
  static void showWarningSubtle(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: scheme.onTertiaryContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
        backgroundColor: scheme.tertiaryContainer,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================================
  // UTILITY METHODS
  // =========================================================================

  /// Show a custom SnackBar with full control
  static void showCustom(
    BuildContext context, {
    required Widget content,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    if (!context.mounted) return;
    
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: content,
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        behavior: behavior,
      ),
    );
  }

  /// Hide any currently showing SnackBar
  static void hide(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Clear all SnackBars from the queue
  static void clearAll(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}