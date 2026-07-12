# 🩺 MedEcos v1.0.0 — Official Release Notes

We are excited to announce the official release of **MedEcos v1.0.0 (Build 1.0.0+1)**! MedEcos is a next-generation healthcare ecosystem connecting patients and doctors seamlessly with smart AI prescription analysis, Ayushman Bharat Digital Mission (ABDM) EHR integration, secure video teleconsultations, and instant Over-The-Air (OTA) updates.

---

## ✨ What's New in v1.0.0

### 🔐 1. Enhanced Security & Verified Onboarding
- **Mandatory Email Verification via Styled HTML OTP Card:** Users must verify their Gmail address with a secure 6-digit one-time password before account creation.
- **High-Reliability Cloud Email Delivery:** Powered by Brevo API & Nodemailer over HTTPS/TLS, ensuring instant delivery across all cloud environments.
- **Role-Based Access Control:** Dedicated, tailored interfaces for both **Patients** and **Doctors**.

### 📄 2. AI-Powered Prescription & Health Record Management
- **Smart Prescription Digitization:** Upload physical prescriptions or medical reports; integrated AI extracts medicines, dosage schedules, and physician instructions.
- **Ayushman Bharat Digital Mission (ABDM) Gateway:** Seamless integration with ABHA IDs and standardized Electronic Health Records (EHR) consent management.

### 📹 3. HD Teleconsultation (Powered by Agora)
- **Real-Time Doctor-Patient Video Calls:** Crisp, low-latency video and audio consultation sessions integrated directly into patient appointments.
- **Interactive Consultation Room:** Secure room management with camera/microphone controls.

### ⚡ 4. Shorebird Over-The-Air (OTA) Code Push
- **Instant Live Patches:** Equipped with **Shorebird Code Push** (`app_id: 8b4d21e9-5f12-4c8a-92e1-4c28f9d0124a`), allowing critical Dart bug fixes and UI updates to deploy instantly to all installed Android devices without requiring APK reinstalls.

---

## 📥 Installation Instructions for Android

1. Download the release APK file (`app-release.apk`).
2. Open the file on your Android device.
3. If prompted, enable **"Install from unknown sources"** for your browser or file manager.
4. Tap **Install** and open **MedEcos**.

---

## 🛠️ Technical Details & Build Info

| Property | Value |
| :--- | :--- |
| **App Name** | MedEcos |
| **Version** | `1.0.0+1` |
| **Android Package** | `com.medecos.app` |
| **Target Platform** | Android (`arm64-v8a`, `armeabi-v7a`, `x86_64`) |
| **Flutter Channel** | Stable (`3.24.x` / `3.44.x`) |
| **OTA Updater** | Shorebird Enabled |
