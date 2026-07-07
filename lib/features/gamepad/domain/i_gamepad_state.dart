// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.
import 'dart:typed_data';

// Enum for hardware-independent button references
enum GamepadButton {
  actionDown, actionRight, actionLeft, actionUp,
  start, select, l1, r1, l2, r2, l3, r3,
  dPadUp, dPadDown, dPadLeft, dPadRight
}

abstract class IGamepadState {
  // Press a button (set its state)
  void pressButton(GamepadButton button, bool pressed);
  
  // Set an analog stick axis value (-1.0 to 1.0)
  void setAxis(int axisIndex, double value);
  
  // Getter for the state 
  Uint8List get currState;
}
