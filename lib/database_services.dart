import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qwip_app/data_classes/booking.dart';
import 'package:qwip_app/data_classes/pod.dart';
import 'package:qwip_app/qr_code_services.dart';

class DatabaseServices {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Pods collection reference
  final CollectionReference podsCollection =
      FirebaseFirestore.instance.collection('pods');

  // Schedules collection reference - won't exist if there are zero bookings made at all on qwip
  final CollectionReference bookingsCollection =
      FirebaseFirestore.instance.collection('bookings');

  Future<List<Pod>> fetchPods() async {
    try {
      final CollectionReference podsCollection = _firestore.collection('pods');
      final QuerySnapshot querySnapshot = await podsCollection.get();

      return querySnapshot.docs
          .map((doc) {
            try {
              return Pod.fromFirestore(
                  doc.id, doc.data() as Map<String, dynamic>);
            } catch (e) {
              print('Error parsing pod with ID ${doc.id}: $e');
              return null; // Exclude invalid pods
            }
          })
          .whereType<Pod>()
          .toList(); // Exclude null values
    } catch (e) {
      print('Error fetching pods: $e');
      return [];
    }
  }

  // Fetch all bookings (in the future this would have to be narrowed somehow)
  // Top Choice - x miles of provided location
  Future<List<Booking>> fetchBookings() async {
    final snapshot = await bookingsCollection.get();
    return snapshot.docs.map((doc) {
      final booking_id = doc.id;
      final data = doc.data()
          as Map<String, dynamic>; // Explicitly cast to Map<String, dynamic>
      return Booking.fromFirestore(booking_id, data);
    }).toList();
  }

  // Fetch bookings for a specific date
  Future<List<Booking>> fetchBookingsByDate(DateTime? date) async {
    if (date == null) {
      return [];
    }

    try {
      // Calculate the start and end of the day for the given date
      final DateTime startOfDay = DateTime(date.year, date.month, date.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      // Query Firestore for bookings within the selected date
      final QuerySnapshot bookingSnapshot = await bookingsCollection
          .where('start_time', isGreaterThanOrEqualTo: startOfDay)
          .where('start_time', isLessThan: endOfDay)
          .get();

      // Convert query results to a list of Booking objects
      return bookingSnapshot.docs.map((doc) {
        final String booking_id = doc.id;
        final data = doc.data() as Map<String, dynamic>;
        return Booking(
          id: booking_id,
          podId: data['pod_id'],
          userId: data['user_id'],
          startTime: (data['start_time'] as Timestamp).toDate(),
          endTime: (data['end_time'] as Timestamp).toDate(),
          createdAt: (data['created_at'] as Timestamp).toDate(),
          price: data['price'],
          notes: data['notes'],
          status: data['status'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching bookings for date $date: $e');
      return [];
    }
  }

  // Fetch all bookings made by User (in the future this would have to be narrowed somehow)
  Future<List<Booking>> fetchBookingsByUserId(String userId) async {
    try {
      // Fetch all bookings for the specific user ID
      final bookingSnapshot =
          await bookingsCollection.where('user_id', isEqualTo: userId).get();

      if (bookingSnapshot.docs.isEmpty) {
        return []; // Return an empty list if no bookings are found
      }

      // Fetch all pods using the existing fetchPods function
      final List<Pod> pods = await fetchPods();

      // Create a map of pod IDs to pod names for quick lookup
      final Map<String, String> podMap = {
        for (var pod in pods) pod.id: pod.name
      };

      // Map booking documents to Booking objects
      return bookingSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final String booking_id = doc.id;

        // Resolve the pod name using the pod ID from the booking
        final podName = podMap[data['pod_id']] ?? 'Unknown Pod';

        // Handle Firestore Timestamps and convert them to DateTime
        final DateTime startTime =
            (data['start_time'] as Timestamp).toDate(); // Convert Timestamp
        final DateTime endTime =
            (data['end_time'] as Timestamp).toDate(); // Convert Timestamp
        final DateTime createdAt =
            (data['created_at'] as Timestamp).toDate(); // Convert Timestamp

        Booking booking = Booking(
          id: booking_id,
          podId: podName, // Use the pod name instead of the pod ID
          userId: data['user_id'],
          startTime: startTime,
          endTime: endTime,
          createdAt: createdAt,
          price: data['price'] as double,
          notes: data['notes'] as String,
          status: data['status'] as String,
        );

        DateTime now = DateTime.now();
        if (booking.startTime.isAfter(now)) {
          booking.status = "upcoming";
        } else if (booking.startTime.isBefore(now) &&
            booking.endTime.isAfter(now)) {
          booking.status = "ongoing";
        } else if (booking.endTime.isBefore(now)) {
          booking.status = "past";
        }

        return booking;
      }).toList();
    } catch (e) {
      print('Error fetching bookings: $e');
      rethrow; // Rethrow the error for further handling
    }
  }

  // Add a new booking to a pod's schedule
  Future<bool> addBooking(Booking booking) async {
    try {
      DocumentReference bookingRef =
          await bookingsCollection.add(booking.toFirestore());
      String bookingId = bookingRef.id;
      Map<String, dynamic> generateQRCodeResponse =
          await QRCodeService.generateQRCode(bookingId);
      print("generateQRCodeResponse: ${generateQRCodeResponse}");
      if (!generateQRCodeResponse["success"]) {
        booking.id = bookingId;
        await deleteBooking(booking);
        throw Exception("Failed to generate QR Code");
      } else {
        print('Booking added successfully: ${generateQRCodeResponse}');
      }
      return true;
    } catch (e) {
      // Log or handle the error
      print('Failed to add booking: $e');
      return false;
    }
  }

  // Delete booking
  Future<bool> deleteBooking(Booking booking) async {
    try {
      await bookingsCollection.doc(booking.id).delete();
      return true;
    } catch (e) {
      print("Error deleting booking: $e");
      return false;
    }
  }

  // Get QR Code of Booking
  Future<String> fetchQRCode(String? bookingId) async {
    if (bookingId == null) {
      throw Exception("Need booking id to fetch QR code");
    }
    final DocumentSnapshot bookingDoc =
        await bookingsCollection.doc(bookingId).get();

    if (bookingDoc.exists) {
      return bookingDoc.get("qr_code_image");
    } else {
      throw Exception("Booking not found");
    }
  }
}
