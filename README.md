# Qwip-MVP

Qwip-MVP is a Flutter-based mobile application designed to provide a seamless booking and QR code experience for soundproof co-working pods. The app allows users to book pods for specific dates and times, view and manage their bookings, and generate QR codes to unlock the pods.

---

## Features

### Booking Management
- **Book Pods**: Users can select a pod, date, start time, and end time to book co-working spaces.
- **Filter Availability**: Pods are filtered based on booking status, availability, and opening/closing times.
- **Booking Actions**:
  - Delete upcoming bookings.
  - Extend ongoing bookings.
  - Rate past bookings.

### QR Code Integration
- **QR Code Generation**: Automatically generates QR codes for bookings upon confirmation.
- **QR Code Viewing**: Users can view QR codes for upcoming bookings.
- **Secure Validation**: QR codes include tamper-proof signatures.

### UI Features
- **Dynamic Popups**:
  - A clean and responsive bottom sheet for viewing bookings.
  - Options to delete, extend, or view QR codes directly from booking tiles.
- **Intuitive Design**:
  - Card-based layouts for bookings.
  - Consistent styling with modern design patterns.
- **Animations**:
  - Smooth transitions for booking and QR code interactions.

---

## Technologies Used

### Frontend
- **Flutter**: For building a cross-platform, high-performance UI.
- **Dart**: For business logic and state management.

### Backend
- **Firebase Firestore**: For real-time database management.
- **Python + FastAPI**: For generating and validating QR codes securely.

### Dependencies
- **Flutter Packages**:
  - `http`: For making API calls to the FastAPI backend.
  - `cloud_firestore`: For interacting with Firebase Firestore.
  - `provider` (if used): For state management.
  - `intl`: For date and time formatting.
  - `qr_flutter`: For rendering QR codes locally (if applicable).


## Installation and Setup

### Prerequisites
- Flutter SDK installed on your machine.
- Firebase project set up with Firestore.
- FastAPI backend running locally or deployed.

### Steps
1. **Clone the Frrontend Repository**:
   ```bash
   git clone https://github.com/shreyassaxena99/qwip-mvp.git
   cd qwip-mvp
   ```
2. **Clone the Backend Repository**:
   ```bash
   git clone https://github.com/shreyassaxena99/qwip_mvp_fastapi.git
   cd qwip_mvp_fastapi
   ```
2. **Install the Dependencies**
   ```bash
   flutter pub get
   ```
3. **Firebase Setup**
   Firebase Setup:
    For iOS, download `GoogleService-Info.plist` and add it to the `ios/Runner` directory.
4. **Run the App**
   ```bash
   flutter run
   ```
5. **Start the Backend**
   - Ensure the FastAPI backend is running at http://127.0.0.1:8000.
   - Use uvicorn to start the server:
   ```bash
   uvicorn main:app --reload
   ```

### Project Structure 
```bash
lib/
├── main.dart                  # Entry point of the app
├── screens/                   # UI screens (e.g., BookingScreen, AuthScreen)
├── components/                # Reusable UI components (e.g., BookingTile)
├── services/                  # Business logic and Firebase interactions (TODO)
└── data_classes/              # Data models (e.g., Booking)
```

### Future Enhancements and Kanban Board
1. **Admin Dashboard**: Manage pods, bookings, and user data.
2. **Payment Integration**: Add Stripe/PayPal for payment processing.
3. **Push Notifications**: Notify users about booking updates and reminders.
4. **Offline Support**: Allow viewing QR codes and bookings offline.

Kanban Board found [here](https://www.notion.so/App-Dev-1690a75a9cdf80a38f09c57aafe8623c)