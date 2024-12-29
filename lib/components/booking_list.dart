import 'package:flutter/material.dart';
import 'package:qwip_app/components/booking_tile.dart';
import 'package:qwip_app/data_classes/booking.dart';

class BookingList extends StatefulWidget {
  final List<Booking> bookings;

  const BookingList({required this.bookings, Key? key}) : super(key: key);

  @override
  State<BookingList> createState() => _BookingListState();
}

class _BookingListState extends State<BookingList> {
  late List<Booking> bookings; // Local state for bookings

  @override
  void initState() {
    super.initState();
    bookings = List.from(widget.bookings); // Initialize local state
  }

  void removeBooking(Booking booking) {
    setState(() {
      bookings.remove(booking); // Remove the booking from the list
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingTile(
          booking: booking,
          onDelete: () => removeBooking(booking), // Callback to remove booking
        );
      },
    );
  }
}
