import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the native background service communication bridge to the isolate
final backgroundServiceProvider = Provider<ServiceInstance>((ref) {
  throw UnimplementedError(
    'backgroundServiceProvider can only be accessed within the background isolate container.',
  );
});
