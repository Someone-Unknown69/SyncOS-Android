import 'dart:typed_data';
import 'package:syncos_android/features/gamepad/domain/i_gamepad_state.dart';

// Controller byte map
// | ------ Action Buttons + Dpad + LR Triggers + Start&Select ---------- | --- Analogs ----- |
// |<-------------------- 16 bits (for 16 buttons) ---------------------> | <-- remaining --> |
//
// In total this will be a 6 byte payload 

class Ps2GamepadState implements IGamepadState {
  final Uint8List _state = Uint8List(6);

  @override
  Uint8List get currState => _state;
  
  @override
  void pressButton(GamepadButton button, bool pressed) {
    final view = ByteData.view(_state.buffer);
    int mask = view.getUint16(0, Endian.little);
    
    if (pressed) {
      mask |= (1 << button.index);
    } else {
      mask &= ~(1 << button.index);
    }
    view.setUint16(0, mask, Endian.little);
  }

  @override
  void setAxis(int axisIndex, double value) {
    if (axisIndex < 0 || axisIndex > 3) return;
    final clamped = value.clamp(-1.0, 1.0);
    _state[axisIndex + 2] = (((clamped + 1.0) / 2.0) * 255.0).round();
  }
}
