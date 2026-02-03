# MedEcos - Medical Ecosystem

A comprehensive Medical Ecosystem platform that connects Doctors, Patients, Pharmacists, and Lab Testers to provide seamless healthcare services.

## Features

### User Types
1. **Doctors**
   - Manage profile with specialization, qualifications, and experience
   - Set consultation fees and availability
   - View and manage appointments
   - Create prescriptions
   - Order lab tests for patients

2. **Patients**
   - Book appointments with doctors
   - View prescriptions and medical history
   - Order medications from pharmacies
   - Schedule and track lab tests
   - Manage personal health information

3. **Pharmacists**
   - Receive and process medication orders
   - View prescriptions
   - Update order status
   - Manage pharmacy inventory

4. **Lab Testers**
   - Receive lab test requests
   - Update test status and upload results
   - Manage available tests and pricing

## Technology Stack

- **Backend**: Node.js, Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT (JSON Web Tokens)
- **Security**: bcryptjs for password hashing

## Project Structure

```
MedEcos/
├── config/
│   └── database.js          # Database configuration
├── models/
│   ├── User.js              # Base user model
│   ├── Doctor.js            # Doctor profile model
│   ├── Patient.js           # Patient profile model
│   ├── Pharmacist.js        # Pharmacist profile model
│   ├── LabTester.js         # Lab Tester profile model
│   ├── Appointment.js       # Appointment model
│   ├── Prescription.js      # Prescription model
│   ├── LabTest.js           # Lab Test model
│   └── PharmacyOrder.js     # Pharmacy Order model
├── routes/
│   ├── auth.js              # Authentication routes
│   ├── doctors.js           # Doctor routes
│   ├── patients.js          # Patient routes
│   ├── pharmacists.js       # Pharmacist routes
│   ├── labTesters.js        # Lab Tester routes
│   ├── appointments.js      # Appointment routes
│   ├── prescriptions.js     # Prescription routes
│   ├── labTests.js          # Lab Test routes
│   └── pharmacyOrders.js    # Pharmacy Order routes
├── middleware/
│   └── auth.js              # Authentication middleware
├── server.js                # Main server file
├── package.json             # Project dependencies
└── .env.example             # Environment variables template
```

## Installation

1. Clone the repository:
```bash
git clone https://github.com/TanishqAswar/MedEcos.git
cd MedEcos
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```bash
cp .env.example .env
```

4. Update `.env` with your configuration:
```
MONGODB_URI=mongodb://localhost:27017/medecos
PORT=3000
JWT_SECRET=your_secure_jwt_secret
NODE_ENV=development
```

5. Start MongoDB (make sure MongoDB is installed and running)

6. Run the application:
```bash
# Development mode with auto-restart
npm run dev

# Production mode
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user

### Doctors
- `GET /api/doctors` - Get all doctors
- `GET /api/doctors/:id` - Get doctor by ID
- `PUT /api/doctors/:id` - Update doctor profile

### Patients
- `GET /api/patients` - Get all patients (doctors only)
- `GET /api/patients/:id` - Get patient by ID
- `PUT /api/patients/:id` - Update patient profile

### Pharmacists
- `GET /api/pharmacists` - Get all pharmacists
- `GET /api/pharmacists/:id` - Get pharmacist by ID
- `PUT /api/pharmacists/:id` - Update pharmacist profile

### Lab Testers
- `GET /api/lab-testers` - Get all lab testers
- `GET /api/lab-testers/:id` - Get lab tester by ID
- `PUT /api/lab-testers/:id` - Update lab tester profile

### Appointments
- `POST /api/appointments` - Create appointment (patients only)
- `GET /api/appointments` - Get appointments (filtered by user)
- `PUT /api/appointments/:id` - Update appointment status
- `DELETE /api/appointments/:id` - Cancel appointment

### Prescriptions
- `POST /api/prescriptions` - Create prescription (doctors only)
- `GET /api/prescriptions` - Get prescriptions (filtered by user)
- `GET /api/prescriptions/:id` - Get prescription by ID
- `PUT /api/prescriptions/:id` - Update prescription status

### Lab Tests
- `POST /api/lab-tests` - Create lab test
- `GET /api/lab-tests` - Get lab tests (filtered by user)
- `GET /api/lab-tests/:id` - Get lab test by ID
- `PUT /api/lab-tests/:id` - Update lab test (lab testers only)

### Pharmacy Orders
- `POST /api/pharmacy-orders` - Create pharmacy order (patients only)
- `GET /api/pharmacy-orders` - Get orders (filtered by user)
- `GET /api/pharmacy-orders/:id` - Get order by ID
- `PUT /api/pharmacy-orders/:id` - Update order status (pharmacists only)

## Usage Examples

### Register a Doctor
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dr. John Smith",
    "email": "doctor@example.com",
    "password": "password123",
    "userType": "doctor",
    "phone": "1234567890",
    "address": "123 Medical Center",
    "additionalInfo": {
      "specialization": "Cardiology",
      "licenseNumber": "DOC123456",
      "qualifications": ["MBBS", "MD"],
      "experience": 10,
      "consultationFee": 100
    }
  }'
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "doctor@example.com",
    "password": "password123"
  }'
```

### Create Appointment (with token)
```bash
curl -X POST http://localhost:3000/api/appointments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "patient": "patient_id",
    "doctor": "doctor_id",
    "appointmentDate": "2024-02-01",
    "timeSlot": {
      "start": "10:00",
      "end": "10:30"
    },
    "reason": "Regular checkup"
  }'
```

## Data Models

### User
- Base model for all user types
- Fields: name, email, password (hashed), userType, phone, address

### Doctor
- Specialization, qualifications, experience
- License number, consultation fee
- Availability schedule, rating

### Patient
- Date of birth, gender, blood group
- Medical history, allergies
- Emergency contact information

### Pharmacist
- Pharmacy name and address
- License number
- Operating hours, services offered

### Lab Tester
- Lab name and address
- License number
- Available tests with pricing
- Accreditations

## Security

- Passwords are hashed using bcryptjs
- JWT tokens for authentication
- Role-based access control
- Protected routes with middleware

## Development

### Prerequisites
- Node.js (v14 or higher)
- MongoDB (v4.4 or higher)
- npm or yarn

### Running Tests
```bash
npm test
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Contact

Project Link: [https://github.com/TanishqAswar/MedEcos](https://github.com/TanishqAswar/MedEcos)
