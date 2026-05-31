import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/theme/theme_notifier.dart';
import 'package:mobile_controller/core/storage/domain/models/app_settings.dart';

final themeProvider = NotifierProvider<ThemeNotifier, AppSettings>(ThemeNotifier.new);