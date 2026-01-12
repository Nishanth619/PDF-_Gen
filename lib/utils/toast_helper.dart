
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// Helper class for showing toast messages
class ToastHelper {
  /// Show success toast
  static void showSuccess(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topCenter,
      showProgressBar: true,
    );
  }

  /// Show error toast
  static void showError(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topCenter,
      showProgressBar: true,
    );
  }

  /// Show info toast
  static void showInfo(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.fillColored,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topCenter,
      showProgressBar: true,
    );
  }

  /// Show warning toast
  static void showWarning(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.fillColored,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topCenter,
      showProgressBar: true,
    );
  }
}
