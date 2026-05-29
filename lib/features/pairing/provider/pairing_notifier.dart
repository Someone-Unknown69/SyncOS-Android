// lib/features/pairing/provider/pairing_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/pairing_service.dart';
import '../../../core/network/provider/connection_provider.dart';

part 'pairing_notifier.g.dart';

@riverpod
class PairingNotifier extends _$PairingNotifier {
  @override
  bool build() => false; // false = idle, true = pairing in progress

  Future<bool> pair(Map<String, dynamic> data) async {
    state = true; // Start loading
    try {
      final manager = ref.read(connectionManagerProvider);
      final service = PairingService(manager);
      return await service.pairWithServer(data);
    } catch (e) {
      return false;
    } finally {
      state = false; // Stop loading
    }
  }
}