import 'package:flutter/material.dart';
import 'package:mobile_controller/main.dart';

class AppSnackbar {
  static void show({
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    snackbarKey.currentState?.removeCurrentSnackBar();
    snackbarKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}