import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qwip_app/data_classes/booking.dart';
import 'package:qwip_app/database_services.dart';

class BookingTile extends StatefulWidget {
  final Booking booking;
  final VoidCallback onDelete; // Callback to notify the parent

  const BookingTile({required this.booking, required this.onDelete, Key? key})
      : super(key: key);

  @override
  State<BookingTile> createState() => _BookingTileState();
}

class _BookingTileState extends State<BookingTile> {
  bool isDeleting = false; // Flag for showing loading state
  bool isLoadingQRCode = false; // Flag for showing loading state

  DatabaseServices db = DatabaseServices();

  Future<void> handleDeleteBooking() async {
    setState(() {
      isDeleting = true; // Show loading indicator
    });

    // Call the database service to delete the booking
    bool deletionStatus = await db.deleteBooking(widget.booking);
    const String messageContent = 'Booking deleted successfully!';
    if (deletionStatus) {
      widget.onDelete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(messageContent)),
    );

    setState(() {
      isDeleting = false; // Hide loading indicator
    });
  }

  Future<void> handleViewQRCode() async {
    try {
      // Fetch the QR Code Base64 from the backend
      String qrCodeBase64 = await db.fetchQRCode(widget.booking.id);
      // Show the bottom sheet with the QR code
      showQRCodeBottomSheet(context, qrCodeBase64);
    } catch (e) {
      // Handle errors (e.g., failed API call)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching QR Code: $e")),
      );
    } finally {
      // Hide loading indicator
      setState(() {
        isLoadingQRCode = false;
      });
    }
  }

  void showQRCodeBottomSheet(BuildContext context, String qrCodeBase64) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow the bottom sheet to grow dynamically
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your QR Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context); // Close the bottom sheet
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // QR Code Section
              Center(
                child: Image.memory(
                  // Decode the Base64 string into image bytes
                  base64Decode(qrCodeBase64),
                  fit: BoxFit.contain,
                  height: 200, // Set a fixed height for the QR code
                  width: 200, // Set a fixed width for the QR code
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  List<PopupMenuEntry<String>> getMenuOptions(Booking booking) {
    final List<PopupMenuEntry<String>> options = [];

    if (booking.status == "upcoming") {
      options.add(
        const PopupMenuItem<String>(
          value: 'view_code',
          child: Text('View QR Code'),
        ),
      );
      options.add(
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete Booking'),
        ),
      );
    } else if (booking.status == "ongoing") {
      options.add(
        const PopupMenuItem<String>(
          value: 'view_code',
          child: Text('View QR Code'),
        ),
      );
      options.add(
        const PopupMenuItem(
          value: 'extend',
          child: Text('Extend Booking'),
        ),
      );
    } else if (booking.status == "past") {
      options.add(
        const PopupMenuItem(
          value: 'rate',
          child: Text('Rate Experience'),
        ),
      );
    }

    return options;
  }

  @override
  Widget build(BuildContext context) {
    final podName =
        widget.booking.podId; // Replace with actual pod name if needed
    final bookingDate = widget.booking.startTime.toLocal();
    final startTime =
        TimeOfDay.fromDateTime(widget.booking.startTime.toLocal());
    final endTime = TimeOfDay.fromDateTime(widget.booking.endTime.toLocal());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Section (Pod Details)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  podName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFAD7E4D), // Brown color
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${bookingDate.year}-${bookingDate.month}-${bookingDate.day}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${startTime.format(context)} - ${endTime.format(context)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          // Right Section (Menu Button and Price)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    right: 12.0), // Match PopupMenuButton padding
                child: Text(
                  '£${widget.booking.price}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (isDeleting)
                const CircularProgressIndicator() // Show loading indicator while deleting
              else
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.grey,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'delete') {
                      handleDeleteBooking(); // Call delete handler
                    }
                    if (value == 'view_code') {
                      handleViewQRCode(); // Call view qr code handler
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return getMenuOptions(widget.booking);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
