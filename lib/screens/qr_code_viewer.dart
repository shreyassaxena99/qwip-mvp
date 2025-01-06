import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class QRCodeViewer extends StatelessWidget {
  final String qrCodeImageBase64;

  QRCodeViewer({required this.qrCodeImageBase64});

  @override
  Widget build(BuildContext context) {
    // Decode the Base64 string into bytes
    Uint8List imageBytes = base64Decode(qrCodeImageBase64);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your QR Code"),
        centerTitle: true, // Centers the title
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context); // Close the QR Code viewer
          },
        ),
      ),
      body: Center(
        child: Image.memory(
          imageBytes, // Render the QR code
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
