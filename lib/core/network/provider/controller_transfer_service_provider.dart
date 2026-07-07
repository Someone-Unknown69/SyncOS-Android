import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/core/network/data/controller_transfer_service.dart';
import 'package:syncos_android/core/network/domain/i_controller_transfer_service.dart';

final controllerTransferServiceProvider = Provider<IControllerTransferService>((ref) {
    return ControllerTransferService();
});
