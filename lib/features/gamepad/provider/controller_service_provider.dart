import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/network/provider/connection_provider.dart';
import 'package:syncos_android/core/network/provider/controller_transfer_service_provider.dart';
import 'package:syncos_android/core/storage/provider/storage_service_provider.dart';
import 'package:syncos_android/features/gamepad/data/controller_service.dart';
import 'package:syncos_android/features/gamepad/data/ps2_gamepad_state.dart';
import 'package:syncos_android/features/gamepad/domain/i_gamepad_state.dart';

final gamepadStateProvider = Provider<IGamepadState>((ref) {
  return Ps2GamepadState();
});

final controllerServiceProvider = Provider<ControllerService>((ref) {
  final transferService = ref.read(controllerTransferServiceProvider);
  final gamepadState = ref.read(gamepadStateProvider);
  final connectionManager = ref.read(connectionManagerProvider);
  final storageService = ref.read(storageServiceProvider);

  return ControllerService(
    transferService,
    gamepadState,
    storageService,
    connectionManager,
  );
});
