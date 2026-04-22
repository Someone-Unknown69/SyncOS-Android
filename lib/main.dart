import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'socket_client.dart';
import 'music_player.dart';
import 'services/socket_processor.dart';
import 'pairing_screen.dart';

// socket data processor
final processor = SocketProcessor();

class DashboardItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  DashboardItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

// The Entry Point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasPaired = prefs.getString('pairing_token') != null;
  runApp(RemoteControllerApp(hasPaired: hasPaired));
}


//Theme config
ThemeData _buildTheme(Brightness brightness) {
  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: Colors.blue,
  );

  return baseTheme.copyWith(
    // Global styling for all TextFields
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    // Global styling for all SnackBars
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}


// Wrapper
class RemoteControllerApp extends StatelessWidget {
  final bool hasPaired;
  const RemoteControllerApp({super.key, required this.hasPaired});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,      // Hides the debug banner
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,            // Forces app to use system mode as theme

      home: hasPaired ? const HomeScreen() : const PairingScreen(),
    );
  }
}

// The "Stateful" Page (Where logic lives)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // Controllers / We can say variables
  final SocketClient client = SocketClient();

  // Customization for UI
  static const double _borderRadius = 20;       // Can be used to change border radius
  static const double _padding = 16;            // Self explanatory
  static const double _spacing = 12;            // Spacing between widgets

  // Dashboard Items
  late final List<DashboardItem> _items = [
    DashboardItem(
      label: 'Send Files',
      icon: Icons.file_copy,
      onTap: () => (),
    ),
    DashboardItem(
      label: 'Run Command',
      icon: Icons.terminal,
      onTap: () => (),
    ),
    DashboardItem(
      label: 'Send Clipboard',
      icon: Icons.document_scanner,
      onTap: () => (),
    ),
    DashboardItem(
      label: 'Gamepad',
      icon: Icons.gamepad,
      onTap: () => (),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _handleConnect();
  }

  // Method to handle connection
  void _handleConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('server_ip');
    final port = prefs.getInt('server_port');
    final httpPort = prefs.getInt('server_http_port');
    final token = prefs.getString('pairing_token');
    
    if (ip != null && port != null) {
      await client.connect(ip, port, httpPort: httpPort, token: token);
    } else {
      // Data missing, reset to Pairing
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PairingScreen()));
      }
    }
  }

  @override
  void dispose() { // Clean up memory when the app closes
    client.disconnect();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    //GestureDetector handles tapping "empty space" to hide keyboard
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent, 

      child: Scaffold(
        appBar: AppBar(
          title: const Text("SyncOS"),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),

            child: Padding(
              padding: const EdgeInsets.all(_padding),
              child: ValueListenableBuilder<SocketConnectionState>(
                valueListenable: client.connectionStatus,
                builder: (context, connectionStatus, child) {
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if(connectionStatus == SocketConnectionState.connected) ...[
                        _statusConnected(),
                        const SizedBox(height: _spacing),

                        ValueListenableBuilder<MediaMetadata>(
                          valueListenable: processor.metadata, 
                          builder: (context, info, child) {
                            return MusicPlayerWidget(
                              imagePath: info.albumArt,
                              trackName: info.title,
                              artistName: info.artist,
                              position: info.position,
                              duration: info.duration,
                              status: info.status,
                              onPlay: () => {},
                              onPrev: () => {},
                              onNext: () => {},
                              albumArtBase64: "", // Not used directly in base64 anymore
                              client: client, // Pass client for seek ops
                            );
                          },
                        ),

                        const SizedBox(height: _spacing),
                        _dashBoard(),
                      ] else if(connectionStatus == SocketConnectionState.connecting) ...[
                        _statusWaiting('Connecting to Server...'),
                      ] else if (connectionStatus == SocketConnectionState.reconnecting) ...[
                        _statusWaiting('Connection lost. Reconnecting...'),
                      ] else 
                        _statusDisconnected(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }


  // Waiting for server approval widget
  Widget _statusWaiting(String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: _spacing),
            Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  strokeWidth: 3,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Please ensure your computer is awake and SyncOS server is running.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // Disconnected
  Widget _statusDisconnected() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Disconnected",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: _spacing),
            
            // Button for connection
            FilledButton.icon(
              onPressed: () => _handleConnect(),
              icon: const Icon(Icons.refresh),
              label: const Text("Reconnect"),
              style: ElevatedButton.styleFrom(
                elevation: 2, 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Info after the connection is established
  Widget _statusConnected() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          
          children: [
            ValueListenableBuilder(
              valueListenable: processor.deviceName,
              builder: (context, name , child) {
                return Text(processor.deviceName.value, style: TextStyle(fontWeight: FontWeight.bold));
              },
            ),

            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  // Display battery info and charging status
                  ValueListenableBuilder(
                    valueListenable: processor.batteryLevel, 
                      builder: (context, level, child) {
                        return ValueListenableBuilder(
                          valueListenable: processor.isCharging, 
                          builder: (context, charging, child) {
                            return Icon(
                            charging ? Icons.battery_charging_full : Icons.battery_std,
                            color: level < 20 ? Colors.red : Colors.green,
                            );
                          },
                        );
                      },
                    ),

                    ValueListenableBuilder(
                      valueListenable: processor.batteryLevel, 
                      builder: (context, level, child) => Text("$level% remaining")
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: _spacing),

            Row( 
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // disconnect button
                FilledButton.icon(
                  onPressed: () => client.disconnect(),
                  icon: const Icon(Icons.power_off),
                  label: const Text("Disconnect"),
                  style: FilledButton.styleFrom(
                    elevation: 0, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_borderRadius),
                    ),
                    backgroundColor: Colors.red,
                    foregroundColor: colorScheme.surfaceBright,
                  ),
                ),

                const SizedBox(width: _spacing,),

                // Ping button
                FilledButton.icon(
                  onPressed: () => client.sendRaw('PING'),
                  icon: const Icon(Icons.network_ping_rounded),
                  label: const Text("Ping"),
                  style: FilledButton.styleFrom(
                    elevation: 0, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_borderRadius),
                    ),
                    backgroundColor: colorScheme.primary,
                  ),
                ),

              ],
            )

          ],
        ),
      ),
    );
  }


  Widget _dashBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
      
        // Using a Grid for both, but changing column count makes it look like a list on desktop
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 1 : 2, // 1 column for list look, 2 for grid
            mainAxisExtent: isDesktop ? 65 : 100, // Height of the item
            crossAxisSpacing: _spacing / 2,
            mainAxisSpacing: _spacing / 2,
          ),
          itemBuilder: (context, index) {
            return _cardTemplate(_items[index], isDesktop);
          },
        );
      },
    );
  }


  Widget _cardTemplate(DashboardItem item, bool isDesktop) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,

      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
            child: !isDesktop ? 
            // For grid 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(item.icon, size: 24, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            )

            // For list
            : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row (
                  children: [
                    Icon(item.icon, color: colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ]
                ),
                Icon(
                  Icons.chevron_right_rounded, 
                  size: 18, 
                  color: colorScheme.outline,
                ),
              ],
            )
          ),
        ),
      );
  }
}

