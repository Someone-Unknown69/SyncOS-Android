import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // to navigate to HomeScreen

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    try {
      final data = jsonDecode(code);
      if (data.containsKey('ip') && data.containsKey('port') && data.containsKey('token') && data.containsKey('http_port')) {
        setState(() => _isProcessing = true);
        _scannerController.stop();

        final ip = data['ip'];
        final port = data['port'];
        final httpPort = data['http_port'];
        final token = data['token'];

        // Perform Handshake
        final response = await http.post(
          Uri.parse('http://$ip:$httpPort/pair'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': token}),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          // Success, save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('server_ip', ip);
          await prefs.setInt('server_port', port);
          await prefs.setInt('server_http_port', httpPort);
          await prefs.setString('pairing_token', token);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully Paired!')),
          );

          // Navigate to HomeScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          throw Exception('Handshake rejected by server');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pairing failed: $e')),
      );
      setState(() => _isProcessing = false);
      _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),
          
          // Custom Overlay
          QRScannerOverlay(overlayColour: Colors.black.withValues(alpha: 0.6)),
          
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Scan SyncOS QR Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class QRScannerOverlay extends StatelessWidget {
  const QRScannerOverlay({super.key, required this.overlayColour});

  final Color overlayColour;

  @override
  Widget build(BuildContext context) {
    double scanArea = 250;
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(overlayColour, BlendMode.srcOut),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: scanArea,
                    width: scanArea,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: CustomPaint(
            foregroundPainter: BorderPainter(),
            child: SizedBox(
              width: scanArea + 10,
              height: scanArea + 10,
            ),
          ),
        ),
      ],
    );
  }
}

class BorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const width = 4.0;
    const radius = 20.0;
    const tRadius = 30.0;
    const rect = Rect.fromLTWH(0, 0, 260, 260);
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    final path = Path()
      ..moveTo(rect.left + tRadius, rect.top)
      ..lineTo(rect.left + radius, rect.top)
      ..quadraticBezierTo(rect.left, rect.top, rect.left, rect.top + radius)
      ..lineTo(rect.left, rect.top + tRadius)
      
      ..moveTo(rect.right - tRadius, rect.top)
      ..lineTo(rect.right - radius, rect.top)
      ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + radius)
      ..lineTo(rect.right, rect.top + tRadius)
      
      ..moveTo(rect.left + tRadius, rect.bottom)
      ..lineTo(rect.left + radius, rect.bottom)
      ..quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - radius)
      ..lineTo(rect.left, rect.bottom - tRadius)
      
      ..moveTo(rect.right - tRadius, rect.bottom)
      ..lineTo(rect.right - radius, rect.bottom)
      ..quadraticBezierTo(rect.right, rect.bottom, rect.right, rect.bottom - radius)
      ..lineTo(rect.right, rect.bottom - tRadius);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
