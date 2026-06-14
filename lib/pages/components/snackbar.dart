// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:syncos_android/main.dart';

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