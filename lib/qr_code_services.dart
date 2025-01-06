import 'dart:convert'; // For JSON encoding/decoding
import 'package:http/http.dart' as http;

class QRCodeService {
  // Base URL for your FastAPI server
  static const String baseUrl = "http://127.0.0.1:8000";

  // Function to generate a QR code
  static Future<Map<String, dynamic>> generateQRCode(String bookingId) async {
    final url = Uri.parse("$baseUrl/generate_qr_code?booking_id=$bookingId");

    try {
      // Send the POST request
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );

      // Handle the response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          "success": true,
          "qr_code_image": responseData["qr_code_image"]
        }; // Return the QR code data
      } else {
        return {"success": false};
      }
    } catch (e) {
      print("Error calling generate_qr_code: $e");
      return {"success": false};
    }
  }
}
