import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/media_service_impl.dart';
import '../domain/i_media_service.dart';

final mediaServiceProvider = Provider<IMediaService>((ref) {
  final service = MediaServiceImpl();
  service.init();
  
  ref.onDispose(() => service.dispose());
  
  return service;
});