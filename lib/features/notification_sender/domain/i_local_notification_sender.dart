// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

abstract class INotificationListener {
  Future<void> start();
  Future<void> stop();
}