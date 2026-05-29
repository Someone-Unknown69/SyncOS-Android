import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_controller/features/battery/provider/remote_battery_state.dart';
import 'package:mobile_controller/features/device_info/provider/remote_device_info_state.dart';
import '../../../core/network/provider/connection_provider.dart';
import '../../../theme/app_theme.dart';

// may make it even better in future
String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Good Morning !';
  if (hour >= 12 && hour < 17) return 'Good Afternoon !';
  if (hour >= 17 && hour < 21) return 'Good Evening !';
  return 'Good Night !';
}

class Header extends ConsumerStatefulWidget {
  const Header({super.key});

  @override
  ConsumerState<Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<Header> with WidgetsBindingObserver {
  late String _currentGreeting;

  @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addObserver(this);
      _currentGreeting = getGreeting();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _currentGreeting = getGreeting();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectionManager = ref.read(connectionManagerProvider);

    return Container(
      margin: const EdgeInsets.only(
        left: AppTheme.spacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentGreeting,
                style: TextStyle(
                  fontSize: 26,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),

              buildContextMenu(
                context: context,
                onPing: () => connectionManager.send("PING", "", {}),
                onDisconnect: () => connectionManager.disconnect(),
              ),
            ]
          ),

          Consumer(
            builder: (context, ref, child) {
              final deviceName = ref.watch(deviceInfoProvider.select((s) => s.name));
              return Text(
                deviceName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold, 
                  color: theme.textTheme.bodyMedium?.color,
                  height: 1.0
                ),
              );
            }
          ),

          const SizedBox(height:  AppTheme.spacing * 2),

          Row(
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(batteryProvider);
                  return _buildBatteryIcon(context, state.level, state.isCharging);
                }
              ),

              Consumer(
                builder: (context, ref, child) {
                  final level = ref.watch(batteryProvider.select((s) => s.level));
                  return Text("$level% remaining");
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildContextMenu({
    required BuildContext context,
    required VoidCallback onDisconnect,
    required VoidCallback onPing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      constraints: const BoxConstraints(
        maxWidth: 140, 
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius / 2),
      ),
      onSelected: (value) {
        if (value == 'ping') onPing();
        if (value == 'disconnect') onDisconnect();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'ping',
          child: Row(
            children: [
              Icon(Icons.sensors_rounded, size: 18, color: colorScheme.onSurface),
              const SizedBox(width: AppTheme.spacing * 0.75),
              Text(
                'Ping',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),

            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'disconnect',
          child: Row(
            children: [
              Icon(Icons.close, size: 18, color: colorScheme.onSurface),
              const SizedBox(width: AppTheme.spacing * 0.75),
              Text(
                'Disconnect',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryIcon(BuildContext context, int level, bool charging) {
    IconData iconData;
    if (level >= 95) {iconData = Icons.battery_full_rounded;}
    else if (level >= 85) {iconData = Icons.battery_6_bar_rounded;}
    else if (level >= 70) {iconData = Icons.battery_5_bar_rounded;}
    else if (level >= 55) {iconData = Icons.battery_4_bar_rounded;}
    else if (level >= 40) {iconData = Icons.battery_3_bar_rounded;}
    else if (level >= 25) {iconData = Icons.battery_2_bar_rounded;}
    else if (level >= 15) {iconData = Icons.battery_1_bar_rounded;}
    else if (level >= 5) {iconData = Icons.battery_0_bar_rounded;}
    else {iconData = Icons.battery_alert_rounded;}

    var iconColor = level <= 20 ? AppTheme.errorColor : AppTheme.successColor;

    if (!charging) {
      return Icon(iconData, color: iconColor);
    }

    iconColor = Colors.blue;

    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(iconData, color: iconColor),
        Positioned(
          top: 8,
          child: Icon(
            Icons.flash_on_rounded,
            size: 10, 
            color: Theme.of(context).colorScheme.onSurface, 
          ),
        ),
      ],
    );
  }
}   
