FixMyCity

FixMyCity is an AI-powered civic issue reporting mobile application built with Flutter. It allows citizens to report road and other civic problems by uploading an image. The image is analyzed using an AI-powered backend, and the generated report can be reviewed, edited, submitted, and tracked.

Features
📸 Capture an issue using the device camera.
🖼️ Select an issue image from the gallery.
🤖 AI-powered civic issue analysis using Gemini.
📝 Review and edit AI-generated report information.
📋 Submit and store reports locally.
🔎 View submitted reports.
📊 View report severity and status.
🛠️ Admin View for managing report status.
💾 Local persistence using SharedPreferences.
🖼️ Custom FixMyCity application logo and launcher icon.
📱 Designed and tested on an Android phone.
Report Flow

The main reporting flow is:

Open FixMyCity.
Select Report an Issue.
Choose Take Photo or Gallery.
Select/capture an image.
The image is sent to the backend.
The backend uses Gemini to analyze the image.
The AI-generated result is displayed.
The citizen can edit the report if necessary.
The report is submitted.
The report appears under My Reports.
An administrator can update the report status from Admin View.
Report Information

Each report can contain:

Issue category
Severity
Description
AI confidence
Location
Submitted image
Report date and time
Current status

Available report statuses are:

Submitted
Under Review
Resolved
Technology Stack
Mobile Application
Flutter
Dart
Material Design
image_picker
shared_preferences
http
Backend
Python
Flask
Gemini API
Storage

The current version uses local device storage through SharedPreferences.

The submitted image path and report information are stored locally for the demo.

Project Structure
fix_my_city/
│
├── android/
├── ios/
├── linux/
├── macos/
├── windows/
│
├── assets/
│   └── images/
│       └── fixmycity_logo.png
│
├── backend/
│   ├── api.py
│   └── README.md
│
├── lib/
│   └── main.dart
│
├── pubspec.yaml
├── pubspec.lock
├── .gitignore
└── README.md

Requirements

Before running the project, make sure you have:

Flutter SDK installed
Dart SDK
Android Studio or another Flutter-compatible IDE
Android device or emulator
Python 3 installed
Required Python packages installed
Gemini API key
Running the Backend

Open a terminal and navigate to the backend folder:

cd backend


Install the required Python packages:

pip install flask


Install any other packages required by api.py if they are not already installed.

Configure the Gemini API key as required by the backend.

Start the backend:

python api.py


The backend runs on:

http://127.0.0.1:5000


For testing with a physical Android phone connected to the same Wi-Fi network, the backend should be accessible using the laptop's local IP address, for example:

http://192.168.1.6:5000


The IP address may be different on another network.

Running the Flutter App

From the project root:

flutter pub get


Connect an Android phone or start an emulator, then run:

flutter run


Make sure the backend is running before testing the AI analysis feature.

Backend URL

The Flutter application communicates with the Flask backend through a backend URL defined in the Flutter code.

For physical-device testing, use the laptop's local Wi-Fi IPv4 address instead of:

127.0.0.1


For example:

static const String _backendUrl = 'http://192.168.1.6:5000';


The correct address depends on the network being used.

Current Demo Limitations

The current version is designed primarily as a project/demo implementation.

Some features are intentionally simplified:

Location is currently represented using a fixed/demo location.
Reports are stored locally on the device.
There are no user accounts.
There is no cloud database.
Admin View is implemented inside the application for demonstration.
Real municipal authority integration is not included.
Future Scope

Potential improvements for a future version include:

Cloud-based report synchronization
GPS location tagging
Integration with municipal authorities
Real-time notifications
Interactive issue map
User accounts
Civic issue analytics
Real-time report tracking
Application Theme

FixMyCity uses a clean blue civic-focused visual theme to communicate reliability, accessibility, and community improvement.

The application includes a custom FixMyCity logo and launcher icon.

Development Status

The current project includes:

Complete Flutter UI
Image capture/gallery selection
AI-powered report analysis
Report editing
Local report persistence
Citizen report viewing
Admin status management
Custom application branding
Flutter-to-Flask backend integration
Project Purpose

FixMyCity demonstrates how AI and mobile technology can be used to make civic issue reporting simpler and more accessible for citizens.

Report. Improve. Connect.