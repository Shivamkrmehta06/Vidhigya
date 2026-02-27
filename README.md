# Vidhigya

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

// Project TRATA
📌 PROJECT OVERVIEW
We are building a Flutter mobile application named TRATA – Your City’s Digital Protector.
This app is a civic issue reporting and women safety platform for India.
It includes:
Civic issue reporting system
Safety heatmap
Offline-first SOS system
Enhanced safety mode called “Nirbhaya Mode”
OTP-based authentication
Modern multi-step onboarding
Clean, minimal, gradient-based UI
The app must follow modern 2025 mobile UI standards.
📱 AUTHENTICATION FLOW
Use mobile number + OTP authentication.
Flow:
Login screen (mobile number input)
OTP verification screen
Check if user exists:
If new user → go to onboarding registration
If existing user → go to Home screen
No email/password authentication.
👤 REGISTRATION FLOW (Multi-step onboarding)
Step 1: Collect full name
Step 2: Collect city
Step 3: Ask if user wants to enable “Nirbhaya Mode”
Step 4: Success screen
If Nirbhaya Mode is enabled:
→ After onboarding, navigate to Emergency Contact Setup screen.
🛡 NIRBHAYA MODE (Enhanced Safety Mode)
When enabled:
Requires minimum 2 emergency contacts
Enables offline SOS
Enables priority alert handling
Stores safety preference in user model
🚨 SOS FEATURE (Offline-first)
SOS must support:
SMS fallback
GPS location fetch
Call emergency number (112 in India)
Send location link to emergency contacts
Work without internet
Use mobile permissions properly.
🏙 CIVIC ISSUE REPORTING
Users can:
Upload image
Auto capture GPS
Select category (Pothole, Streetlight, Garbage, etc.)
Add description
Submit report
Reports should be stored in Firebase (or mock local storage initially).
🗺 SAFETY MAP
Map should show:
High risk zones (red)
Medium risk zones (orange)
Safe zones (green)
Police stations
Women shelters
Use Google Maps Flutter package.
🎨 UI REQUIREMENTS
Design style:
Minimal, clean
White background
Gradient used only for CTA buttons
Modern rounded corners (16–20px)
Large spacing
No heavy shadows
Poppins or Inter font
Professional layout
AppBar must include TRATA logo image from assets.
🗂 FOLDER STRUCTURE
lib/
├── main.dart
├── theme/
├── models/
├── services/
├── screens/
│ ├── auth/
│ ├── onboarding/
│ ├── home/
│ ├── sos/
│ ├── report/
│ └── safety/
└── widgets/
Use clean architecture principles.
📦 DATA MODELS
User:
id
name
phoneNumber
city
nirbhayaModeEnabled (bool)
emergencyContacts (List)
Report:
id
userId
category
imageUrl
location
description
status
🔐 SECURITY
Use OTP verification
Encrypt sensitive user data
Location sharing only during SOS
Do not expose emergency contacts publicly
🎯 DEVELOPMENT ORDER
Authentication (UI + OTP mock)
Onboarding flow
Home screen layout
SOS UI
Emergency contact screen
Civic report screen
Map integration
Firebase integration
🚀 END PROMPT