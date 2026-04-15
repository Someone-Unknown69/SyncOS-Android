import 'package:flutter/material.dart';
import 'socket_client.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'music_player.dart';

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
void main() {
  runApp(const RemoteControllerApp());
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
  const RemoteControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,      // Hides the debug banner
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,            // Forces app to use system mode as theme

      home: const HomeScreen(),               // The starting page
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
  final TextEditingController _ipController = TextEditingController();
  final  int _port = 9999; // Default is always 9999
  final SocketClient client = SocketClient();

  // Customization for UI
  static const double _borderRadius = 20;       // Can be used to change border radius
  static const double _borderRadiusInput = 12;  // Input field border radius
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

  // Method to handle connection
  void _handleConnect() async {
    String ip = _ipController.text.trim();
    final address = InternetAddress.tryParse(ip);

    if (address?.type != InternetAddressType.IPv4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid IP address"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    debugPrint("Connecting to $ip on port $_port...");
    await client.connect(ip, _port);
  }


  @override
  void dispose() { // Clean up memory when the app closes
    _ipController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    //GestureDetector handles tapping "empty space" to hide keyboard
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent, 

      child: Scaffold(
        appBar: AppBar(title: const Text("Remote Controller")),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),

            child: Padding(
              padding: const EdgeInsets.all(_padding),
              child: ValueListenableBuilder<int>(
                valueListenable: client.connectionStatus,
                builder: (context, connectionStatus, child) {
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if(connectionStatus == 2) ...[
                        _statusConnected(),
                        const SizedBox(height: _spacing),

                        MusicPlayerWidget(
                          imagePath: 'assets/images/album2.png',
                          trackName: "We Don't Talk Anymore",
                          artistName: "Charlie Puth & Selena Gomez",
                          onPlay: () => {debugPrint("Play")},
                          onPrev: () => {debugPrint("Prev")},
                          onNext: () => {debugPrint("Next")}
                        ),

                        const SizedBox(height: _spacing),
                        _dashBoard(),
                      ] else if(connectionStatus == 1) ...[
                        _statusWaiting(),
                      ] else 
                        _statusNotConnected(),
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
  Widget _statusWaiting() {
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
              'Waiting for approval',
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
                    'Request sent. Waiting for the server to accept the connection.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: _spacing),
            Text(
              'If approval is denied, the connection will close automatically.',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }


  // IP address input widget
  Widget _statusNotConnected() {
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
              "Connection Settings",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: _spacing), 
            
            TextField(
              controller: _ipController, 
              keyboardType: const TextInputType.numberWithOptions(decimal: true),

              // formatting the text
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                
                LengthLimitingTextInputFormatter(15), 
              ],

              decoration: InputDecoration(
                prefixIcon: Icon(Icons.laptop_rounded),
                labelText: "IP Address",
                hintText: "e.g. 192.168.1.5",
                border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_borderRadiusInput),
                    ),
                    // The border when the field is NOT focused
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_borderRadiusInput),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    // The border when the user is typing
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_borderRadiusInput),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
              ),
            ),
            
            const SizedBox(height: _spacing),

            // Button for connection
            FilledButton.icon(
              onPressed: () => _handleConnect(),
              icon: const Icon(Icons.power),
              label: const Text("Connect"),
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
              valueListenable: client.deviceName,
              builder: (context, name , child) {
                return Text(client.deviceName.value, style: TextStyle(fontWeight: FontWeight.bold));
              },
            ),

            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  // Display battery info and charging status
                  ValueListenableBuilder(
                    valueListenable: client.batteryLevel, 
                      builder: (context, level, child) {
                        return ValueListenableBuilder(
                          valueListenable: client.isCharging, 
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
                      valueListenable: client.batteryLevel, 
                      builder: (context, level, child) => Text("$level% remaining")
                    ),
                  ],
                ),

                // Displays latency updates
                ValueListenableBuilder(
                  valueListenable: client.latency, 
                  builder: (context, value, child) {
                    return Row(
                      children: [
                        const Icon(Icons.sensors, size: 16, color: Colors.grey),
                        Text(
                          " $value ms",
                          style: TextStyle(
                            color: value < 50 ? Colors.green : Colors.orange,
                            fontSize: 12,
                          ),
                        )
                      ],
                    );
                  }
                )

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
                  onPressed: () => client.send('PING'),
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

