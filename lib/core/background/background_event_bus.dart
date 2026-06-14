import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundEventBus {
  static ServiceInstance? _service;
  
  static void setService(ServiceInstance service) => _service = service;
  
  static void emit(String event, Map<String, dynamic> data) {
    _service?.invoke(event, data);
  }
}