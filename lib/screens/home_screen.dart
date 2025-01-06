import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qwip_app/components/booking_list.dart';
import 'package:qwip_app/database_services.dart';
import 'package:qwip_app/data_classes/pod.dart';
import 'package:qwip_app/data_classes/booking.dart';
import 'package:qwip_app/components/time_selection_dropdown.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:qwip_app/components/map_component.dart';
import 'package:qwip_app/components/filter_pods.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isIslandVisible = false; // Track island visibility
  late MapTileLayerController _mapController;
  late MapZoomPanBehavior _zoomPanBehavior;

  final List<String> timeSlots = List.generate(
    24,
    (index) =>
        "${index == 0 || index == 12 ? 12 : index % 12}:00 ${index < 12 ? 'AM' : 'PM'}",
  );

  // Selected date
  DateTime? selectedDate;

  // Selected start and end times
  String? selectedStartTime;
  String? selectedEndTime;

  // Filtered pods to display on the map
  List<Pod> filteredPods = [];
  List<Pod> allPods = [];

  // Current pod selected
  Pod? selectedPod;

  DatabaseServices db = DatabaseServices();

  void filterPods() async {
    print("Start time selected: $selectedStartTime");
    print("End time selected: $selectedEndTime");

    if (selectedStartTime == null || selectedEndTime == null) {
      print("Error: Start or end time is not selected.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end times')),
      );
      return;
    }

    int startIndex = timeSlots.indexOf(selectedStartTime!);
    int endIndex = timeSlots.indexOf(selectedEndTime!);

    if (endIndex <= startIndex) {
      print("Error: End time must be after start time.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final List<String> selectedRange = timeSlots.sublist(startIndex, endIndex);
    print("Selected range: $selectedRange");

    try {
      // Use database accessor to fetch bookings in currentDate
      final List<Booking> bookings = await db.fetchBookingsByDate(selectedDate);

      print("Fetched ${bookings.length} bookings for the selected date.");

      print('Before updating filteredPods: ${filteredPods.hashCode}');
      // Ensure `filteredPods` gets a new reference
      setState(() {
        filteredPods = List<Pod>.from(allPods.where((pod) {
          // Parse pod opening and closing times
          final openingTimeIndex = timeSlots.indexOf(pod.openingTime);
          final closingTimeIndex = timeSlots.indexOf(pod.closingTime);

          if (openingTimeIndex == -1 || closingTimeIndex == -1) {
            print("Invalid opening or closing times for pod: ${pod.name}");
            return false; // Exclude pod if its opening or closing time is invalid
          }

          // Check if the selected time range falls within the pod's operating hours
          bool isWithinOperatingHours =
              startIndex >= openingTimeIndex && endIndex <= closingTimeIndex;

          if (!isWithinOperatingHours) {
            return false; // Exclude pods outside their operating hours
          }

          // Check for conflicts with existing bookings
          bool isConflicting = bookings.any((booking) {
            if (booking.podId != pod.id) return false;

            // Compare the selected time range with booking start and end times
            final bookingStartIndex = timeSlots.indexOf(
              "${booking.startTime.hour == 0 || booking.startTime.hour == 12 ? 12 : booking.startTime.hour % 12}:00 ${booking.startTime.hour < 12 ? 'AM' : 'PM'}",
            );
            final bookingEndIndex = timeSlots.indexOf(
              "${booking.endTime.hour == 0 || booking.endTime.hour == 12 ? 12 : booking.endTime.hour % 12}:00 ${booking.endTime.hour < 12 ? 'AM' : 'PM'}",
            );

            // Check if the selected time range overlaps with the booking time
            return !(endIndex <= bookingStartIndex ||
                startIndex >= bookingEndIndex);
          });

          return !isConflicting; // Include only pods with no conflicts
        }).toList());

        // If the selected pod is not in the filtered list, set selectedPod to null
        if (selectedPod != null &&
            !filteredPods.any((pod) => pod.id == selectedPod!.id)) {
          selectedPod = null;
        }
      });
      print("After updating filtered pods: ${filteredPods.hashCode}");
    } catch (e) {
      print("Error fetching bookings: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching pod bookings.')),
      );
    }
    toggleIslandVisibility(); // Hide island after filtering
  }

  void toggleIslandVisibility() {
    setState(() {
      isIslandVisible = !isIslandVisible; // Toggle visibility
    });
  }

  Future<void> fetchPodData() async {
    try {
      final List<Pod> pods = await db.fetchPods();
      setState(() {
        filteredPods = pods; // Update the filteredPods with fetched data
        allPods = pods; // Update allPods with fetched data
      });
    } catch (e) {
      print('Error fetching pods: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize map components
    _mapController = MapTileLayerController();
    _zoomPanBehavior = MapZoomPanBehavior(
      enablePanning: true,
      enablePinching: true,
      minZoomLevel: 5,
      maxZoomLevel: 18,
    );

    // Fetch pod data from Firebase
    fetchPodData();

    // Use widget.userId for initialization, data fetching, etc.
    print("User ID: ${widget.userId}");
  }

  void _onMenuItemSelected(String value) async {
    if (value == 'view_bookings') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => FutureBuilder<List<Booking>>(
          future: db.fetchBookingsByUserId(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            final bookings = snapshot.data;
            if (bookings == null || bookings.isEmpty) {
              return const Center(
                child: Text('No bookings found.'),
              );
            }
            return Stack(
              children: [
                // Booking List
                Padding(
                  padding: const EdgeInsets.only(top: 100), // Adjusted padding
                  child: BookingList(bookings: bookings),
                ),
                // Header (Your Bookings and Close Button)
                Positioned(
                  top:
                      MediaQuery.of(context).size.height * 0.06, // 15% from top
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Bookings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context); // Close the modal sheet
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else if (value == 'logout') {
      try {
        await FirebaseAuth.instance.signOut();
        print('User logged out successfully.');
      } catch (e) {
        print('Error logging out: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error logging out. Please try again.')),
        );
      }
    }
  }

  int computeBookingPrice(int hourlyPrice, String? startTime, String? endTime) {
    if (startTime == null || endTime == null) {
      throw Exception("Require startTime and endTime to compute booking price");
    }
    DateTime parsedStartTime = parseTime(startTime);
    DateTime parsedEndTime = parseTime(endTime);

    Duration difference = parsedEndTime.difference(parsedStartTime);

    return hourlyPrice * difference.inHours;
  }

  void showConfirmationOverlay(
    BuildContext context,
    Pod pod,
    String? startTime,
    String? endTime,
    int bookingPrice,
    VoidCallback onConfirm,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Confirm Your Booking',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Pod Details
              Text(
                pod.name,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                pod.address,
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                '£${bookingPrice.toString()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAD7E4D),
                ),
              ),
              const SizedBox(height: 16),
              // Booking Times
              Text(
                'Time: ${startTime ?? 'N/A'} to ${endTime ?? 'N/A'}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Confirm and Cancel Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onConfirm();
                        Navigator.pop(context); // Close the overlay
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAD7E4D),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Confirm Booking',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context), // Close overlay
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFAD7E4D)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFFAD7E4D)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void handleBooking(Pod pod, DateTime date, String startTime, String endTime,
      int bookingPrice) async {
    // Display a SnackBar to confirm the booking
    Booking booking = Booking(
        podId: pod.id,
        userId: widget.userId,
        startTime: parseTime(startTime, date: date),
        endTime: parseTime(endTime, date: date),
        createdAt: DateTime.now(),
        price: bookingPrice,
        notes: "no notes",
        status: "confirmed");
    bool status = await db.addBooking(booking);
    String alertText = status
        ? 'Booked "${pod.name}" from $startTime to $endTime! View QR Code in "View Bookings"'
        : "Failed to book pod";

    if (status) {
      // Update the state: Remove the booked pod and clear selectedPod
      setState(() {
        filteredPods = filteredPods.where((p) => p.id != pod.id).toList();
        selectedPod = null; // Clear the active selection
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alertText,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFAD7E4D), // Brown background
        duration: const Duration(seconds: 3), // Duration for SnackBar
      ),
    );
  }

  DateTime parseTime(String time, {DateTime? date}) {
    final DateTime dateToUse = date ?? DateTime.now();

    // Extract hour, minute, and period (AM/PM) using a regex
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s?(AM|PM)$').firstMatch(time);

    if (match == null) {
      throw FormatException('Invalid time format: $time');
    }

    int hour = int.parse(match.group(1)!); // Extract hour
    final int minute = int.parse(match.group(2)!); // Extract minute
    final String period = match.group(3)!; // Extract AM/PM

    // Adjust hour based on AM/PM
    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(
        dateToUse.year, dateToUse.month, dateToUse.day, hour, minute);
  }

  String getPodStatus(String? openingTime, String? closingTime) {
    final currentTime = DateTime.now();

    if (openingTime == null || closingTime == null) {
      print("Opening or closing time are null therefore marking as closed");
      return 'Closed'; // defaults to Closed if opening or closing time not provided
    }

    print("Pod opening time: ${openingTime}, pod closing time: ${closingTime}");

    final opening = parseTime(openingTime);
    final closing = parseTime(closingTime);

    print(
        "Parsed opening and closing times: Opening= ${opening}, Closing=${closing}");

    // Compare times
    if (currentTime.isAfter(opening) && currentTime.isBefore(closing)) {
      if (closing.difference(currentTime).inMinutes <= 30) {
        return 'Closes Soon'; // Yellow
      }
      return 'Open Now'; // Green
    }
    return 'Closed'; // Red
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final topOffset = screenHeight * 0.05; // 5% of screen height
    final rightOffset = screenWidth * 0.05; // 5% of screen width

    // Generate valid end time options dynamically based on selected start time
    final List<String> validEndTimes = selectedStartTime != null
        ? timeSlots.sublist(timeSlots.indexOf(selectedStartTime!) + 1)
        : timeSlots;

    return Scaffold(
      body: Stack(
        children: [
          // Map layer
          Positioned.fill(
            child: AnimatedOpacity(
              opacity:
                  isIslandVisible ? 0.15 : 1, // Dim map when island is visible
              duration: const Duration(milliseconds: 300),
              child: MapComponent(
                key: ValueKey(filteredPods.hashCode),
                onMarkerTapped: (pod) {
                  print('Marker tapped');
                  setState(() {
                    selectedPod = pod;
                  });
                  print("selectedPod: ${selectedPod}");
                },
                pods: filteredPods,
              ),
            ),
          ),
          // Centered Island
          if (isIslandVisible)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width *
                    0.9, // 90% of screen width
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Fit content size dynamically
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Close Button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: toggleIslandVisibility,
                        constraints: const BoxConstraints(
                          minHeight: 24,
                          minWidth: 24,
                        ), // Adjusts the button size
                        padding:
                            const EdgeInsets.all(0), // Removes extra padding
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    const Text(
                      'Book Your Pod Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAD7E4D), // Brown text color
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date Picker Row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime.now(), // Prevent past dates
                                lastDate: DateTime.now().add(const Duration(
                                    days: 14)), // Limit to two weeks
                                builder: (BuildContext context, Widget? child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Color(
                                            0xFFAD7E4D), // Brown color for selection
                                        onPrimary: Colors
                                            .white, // Text color on selection
                                        onSurface:
                                            Colors.black, // Default text color
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  selectedDate =
                                      pickedDate; // Update selected date
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedDate != null
                                        ? "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}"
                                        : "Select Date",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Time Selection Row
                    Row(
                      children: [
                        Expanded(
                          child: TimeSelectionDropdown(
                            label: 'Start Time',
                            selectedValue: selectedStartTime,
                            items: timeSlots,
                            onChanged: (value) {
                              setState(() {
                                selectedStartTime = value;
                                // Reset end time if it’s no longer valid
                                if (selectedEndTime != null &&
                                    timeSlots.indexOf(selectedEndTime!) <=
                                        timeSlots.indexOf(value!)) {
                                  selectedEndTime = null;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TimeSelectionDropdown(
                            label: 'End Time',
                            selectedValue: selectedEndTime,
                            items: validEndTimes,
                            onChanged: (value) {
                              setState(() => selectedEndTime = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search Button
                    // Row for Filter Pods Button (Centered)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilterPodsButton(
                          selectedStartTime: selectedStartTime,
                          selectedEndTime: selectedEndTime,
                          timeSlots: timeSlots,
                          onFilter: filterPods,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          // Circular Search Button
          if (!isIslandVisible)
            Positioned(
              bottom: 32,
              left: MediaQuery.of(context).size.width * 0.5 -
                  28, // Centered horizontally
              child: FloatingActionButton(
                onPressed: toggleIslandVisibility,
                backgroundColor: const Color(0xFFAD7E4D), // Brown color
                child: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          // Profile view button in the top-right corner
          Positioned(
            top: topOffset, // 5% from the top
            right: rightOffset, // 5% from the right
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFAD7E4D), // Brown background
                shape: BoxShape.circle, // Circular shape
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51), // Slight shadow
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.person,
                  size: 28,
                  color: Color(0xFFF9F8F5), // White icon
                ),
                color: Colors.white, // Dropdown background color
                onSelected: _onMenuItemSelected,
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'view_bookings',
                    child: Row(
                      children: const [
                        Icon(Icons.event, size: 20, color: Colors.black),
                        SizedBox(width: 8),
                        Text('View Bookings'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: const [
                        Icon(Icons.logout, size: 20, color: Colors.black),
                        SizedBox(width: 8),
                        Text('Log Out'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Pod details card at the bottom
          if (selectedPod != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withAlpha((0.1 * 255).toInt()), // Slight shadow
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pod Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://via.placeholder.com/150',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Pod Title and Rating Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedPod!.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          getPodStatus(selectedPod?.openingTime,
                              selectedPod?.closingTime),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: getPodStatus(selectedPod?.openingTime,
                                        selectedPod?.closingTime) ==
                                    'Open Now'
                                ? Colors.green
                                : getPodStatus(selectedPod?.openingTime,
                                            selectedPod?.closingTime) ==
                                        'Closes Soon'
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'N/A',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Pod Description
                    Text(
                      selectedPod!.description,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    // Book Now Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (selectedStartTime != null &&
                                selectedEndTime != null)
                            ? () {
                                // Compute price of theoretical booking
                                int bookingPrice = computeBookingPrice(
                                    selectedPod!.price,
                                    selectedStartTime,
                                    selectedEndTime);
                                // Trigger confirmation overlay
                                showConfirmationOverlay(
                                  context,
                                  selectedPod!,
                                  selectedStartTime,
                                  selectedEndTime,
                                  bookingPrice,
                                  () {
                                    handleBooking(
                                        selectedPod!,
                                        selectedDate!,
                                        selectedStartTime!,
                                        selectedEndTime!,
                                        bookingPrice);
                                  },
                                );
                              }
                            : null, // Disable button if times are not selected
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFAD7E4D), // Brown color
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          (selectedStartTime != null &&
                                  selectedEndTime != null &&
                                  selectedDate != null)
                              ? 'Book Pod from $selectedStartTime to $selectedEndTime'
                              : 'Select date and times to book this pod', // Placeholder text
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Like and Close Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Like Button
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Liked this pod!')),
                            );
                          },
                        ),
                        // Close Button
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              selectedPod = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
