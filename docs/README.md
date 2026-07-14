# MedEcos Architecture & Deep-Dive Documentation

Welcome to the **MedEcos Technical Architecture Hub**. This folder contains detailed, end-to-end architectural explainers, flowcharts, Mermaid diagrams, and code flows for every core component and complex subsystem in MedEcos.

---

## Technical Deep-Dive Guides

1. **[01_Redis_Distributed_Systems_Data_Engineering.md](./01_Redis_Distributed_Systems_Data_Engineering.md)**
   - Redis sub-millisecond caching (ABHA sessions, drug interaction matrices, token-bucket rate limiters).
   - Event-Driven Microservices (Apache Kafka / RabbitMQ asynchronous decoupling).
   - Data Engineering & ML Lakehouse Pipeline (Change Data Capture via Debezium, Spark Streaming, HIPAA anonymization, Medication Adherence Prediction ML).

2. **[02_Cloudinary_File_Uploads_End_To_End.md](./02_Cloudinary_File_Uploads_End_To_End.md)**
   - End-to-end media ingestion flow across cross-platform Flutter (`file_picker`), Node.js Express memory storage (`multer`), and secure Cloudinary CDN asset streaming (`upload_stream`).

3. **[03_Agora_Video_Calling_Architecture.md](./03_Agora_Video_Calling_Architecture.md)**
   - WebRTC & Agora RTC Engine teleconsultation architecture (`agora_rtc_engine`), native permission handling (`permission_handler`), event callbacks, and GPU-accelerated video canvas rendering (`AgoraVideoView`).

4. **[04_AI_Chatbot_Vaidya_Architecture.md](./04_AI_Chatbot_Vaidya_Architecture.md)**
   - Conversational AI Chatbot (`Vaidya`) powered by Google Gemini 2.5 Flash (`gemini-2.5-flash`), spiritual Bhagavad Gita holistic persona (*Yukta-ahara-viharasya*), and local zero-latency drug interaction clash matrix.

5. **[05_AI_Prescription_OCR_Extraction.md](./05_AI_Prescription_OCR_Extraction.md)**
   - Structured prescription OCR extraction using Gemini Vision AI, strict JSON schema enforcement (`doctorName`, `prescriptionDate`, `medicines`), human-in-the-loop verification dialogs, and custom reminder synchronization.

6. **[06_Gradle_Build_System_In_Flutter.md](./06_Gradle_Build_System_In_Flutter.md)**
   - Deep dive into Android native compilation in Flutter: `settings.gradle`, `build.gradle`, native C++ NDK linkers, ABI splits, and Android manifest permissions.

7. **[07_Brevo_Gmail_Email_Service_Architecture.md](./07_Brevo_Gmail_Email_Service_Architecture.md)**
   - End-to-end multi-tier email service architecture combining Brevo v3 HTTP REST API (`Port 443`), Resend API fallback, and Nodemailer Gmail SMTP (`Port 587/465`). Includes complete sequence flows, cloud firewall traversal strategy, stylized HTML OTP templates, and `.env` developer setup guide.

8. **[08_Health_Vault_Medical_Locker_Architecture.md](./08_Health_Vault_Medical_Locker_Architecture.md)**
   - Secure digital Health Vault & Medical Locker architecture inside MedEcos. Details custom and default folder management (`FolderModel`), multi-format document handling (`MedicalDocumentModel` supporting PDF, Gallery photos, and Camera capture), local/cloud persistence (`HealthVaultService` + `SharedPreferences`), and UI flows (`HealthVaultScreen` & `FolderDetailsScreen`).

