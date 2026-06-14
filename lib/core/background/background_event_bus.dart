// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundEventBus {
  static ServiceInstance? _service;
  
  static void setService(ServiceInstance service) => _service = service;
  
  static void emit(String event, Map<String, dynamic> data) {
    _service?.invoke(event, data);
  }
}