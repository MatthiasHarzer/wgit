import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrCodeScanView extends StatelessWidget {
  final Function(String) onRead;
  final String title;
  const QrCodeScanView({Key? key, required this.onRead, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: MobileScanner(
        allowDuplicates: false,
        onDetect: (barcode, args) {
          if (barcode.rawValue == null) {
            // debugPrint('Failed to scan Barcode');
          } else {
            final String code = barcode.rawValue!;
            onRead(code);
            Navigator.pop(context);
            // debugPrint('Barcode found! $code');
          }
        },
      ),
    );
  }
}
