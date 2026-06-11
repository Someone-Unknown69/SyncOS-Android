import 'package:flutter/foundation.dart';

String engineNamespace = '[MAIN]';
void logDebug(String tag, String message) {
  debugPrint('$engineNamespace [$tag] -> $message');
}