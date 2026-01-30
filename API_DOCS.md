# API Documentation

## Base URL
```
http://localhost:3000/api
```

## Authentication

All endpoints except `/auth/register` and `/auth/login` require authentication.

Include the JWT token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

## User Types

The system supports four user types:
- `doctor` - Medical doctors who can create prescriptions and order tests
- `patient` - Patients who can book appointments and order medications
- `pharmacist` - Pharmacy staff who fulfill medication orders
- `lab_tester` - Lab technicians who process test orders

## Endpoints

### Authentication

#### Register User
```
POST /auth/register
```

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "userType": "patient",
  "phone": "1234567890",
  "address": "123 Main St",
  "additionalInfo": {
    // Type-specific fields
  }
}
```

**Additional Info by User Type:**

**Doctor:**
```json
{
  "specialization": "Cardiology",
  "licenseNumber": "DOC123456",
  "qualifications": ["MBBS", "MD"],
  "experience": 10,
  "consultationFee": 100
}
```

**Patient:**
```json
{
  "dateOfBirth": "1990-01-01",
  "gender": "male",
  "bloodGroup": "O+"
}
```

**Pharmacist:**
```json
{
  "pharmacyName": "ABC Pharmacy",
  "licenseNumber": "PHARM123456",
  "pharmacyAddress": "456 Medical Plaza"
}
```

**Lab Tester:**
```json
{
  "labName": "XYZ Diagnostics",
  "licenseNumber": "LAB123456",
  "labAddress": "789 Healthcare Building"
}
```

**Response:**
```json
{
  "message": "User registered successfully",
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "name": "John Doe",
    "email": "john@example.com",
    "userType": "patient"
  }
}
```

#### Login
```
POST /auth/login
```

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "message": "Login successful",
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "name": "John Doe",
    "email": "john@example.com",
    "userType": "patient"
  }
}
```

### Doctors

#### Get All Doctors
```
GET /doctors
```

**Response:**
```json
[
  {
    "_id": "doctor_id",
    "userId": {
      "name": "Dr. Smith",
      "email": "smith@example.com",
      "phone": "1234567890",
      "address": "Medical Center"
    },
    "specialization": "Cardiology",
    "qualifications": ["MBBS", "MD"],
    "experience": 10,
    "licenseNumber": "DOC123456",
    "consultationFee": 100,
    "rating": 4.5
  }
]
```

#### Get Doctor by ID
```
GET /doctors/:id
```

#### Update Doctor Profile
```
PUT /doctors/:id
```
**Authorization:** Doctor only

### Patients

#### Get All Patients
```
GET /patients
```
**Authorization:** Doctor only

#### Get Patient by ID
```
GET /patients/:id
```

#### Update Patient Profile
```
PUT /patients/:id
```
**Authorization:** Patient only

### Appointments

#### Create Appointment
```
POST /appointments
```
**Authorization:** Patient only

**Request Body:**
```json
{
  "patient": "patient_id",
  "doctor": "doctor_id",
  "appointmentDate": "2024-02-01T10:00:00.000Z",
  "timeSlot": {
    "start": "10:00",
    "end": "10:30"
  },
  "reason": "Regular checkup"
}
```

#### Get Appointments
```
GET /appointments
```
Returns appointments filtered by user type (patients see their appointments, doctors see their scheduled appointments)

#### Update Appointment
```
PUT /appointments/:id
```

**Request Body:**
```json
{
  "status": "completed",
  "notes": "Patient doing well"
}
```

#### Cancel Appointment
```
DELETE /appointments/:id
```
**Authorization:** Patient only

### Prescriptions

#### Create Prescription
```
POST /prescriptions
```
**Authorization:** Doctor only

**Request Body:**
```json
{
  "patient": "patient_id",
  "doctor": "doctor_id",
  "appointment": "appointment_id",
  "diagnosis": "Hypertension",
  "medications": [
    {
      "medicineName": "Lisinopril",
      "dosage": "10mg",
      "frequency": "Once daily",
      "duration": "30 days",
      "instructions": "Take in the morning"
    }
  ],
  "notes": "Follow up in 2 weeks"
}
```

#### Get Prescriptions
```
GET /prescriptions
```
Returns prescriptions filtered by user type

#### Get Prescription by ID
```
GET /prescriptions/:id
```

#### Update Prescription Status
```
PUT /prescriptions/:id
```
**Authorization:** Doctor or Pharmacist

### Lab Tests

#### Create Lab Test
```
POST /lab-tests
```
**Authorization:** Doctor or Patient

**Request Body:**
```json
{
  "patient": "patient_id",
  "doctor": "doctor_id",
  "labTester": "lab_tester_id",
  "testName": "Complete Blood Count",
  "testCode": "CBC001",
  "scheduledDate": "2024-02-05T09:00:00.000Z",
  "price": 50
}
```

#### Get Lab Tests
```
GET /lab-tests
```
Returns lab tests filtered by user type

#### Get Lab Test by ID
```
GET /lab-tests/:id
```

#### Update Lab Test
```
PUT /lab-tests/:id
```
**Authorization:** Lab Tester only

**Request Body:**
```json
{
  "status": "completed",
  "results": {
    "findings": "All values within normal range",
    "reportUrl": "https://example.com/reports/123.pdf",
    "completedDate": "2024-02-05T14:00:00.000Z"
  }
}
```

### Pharmacy Orders

#### Create Pharmacy Order
```
POST /pharmacy-orders
```
**Authorization:** Patient only

**Request Body:**
```json
{
  "patient": "patient_id",
  "pharmacist": "pharmacist_id",
  "prescription": "prescription_id",
  "medications": [
    {
      "medicineName": "Lisinopril",
      "quantity": 30,
      "price": 20
    }
  ],
  "totalAmount": 20,
  "deliveryType": "pickup"
}
```

#### Get Pharmacy Orders
```
GET /pharmacy-orders
```
Returns orders filtered by user type

#### Get Pharmacy Order by ID
```
GET /pharmacy-orders/:id
```

#### Update Order Status
```
PUT /pharmacy-orders/:id
```
**Authorization:** Pharmacist only

**Request Body:**
```json
{
  "status": "ready",
  "completedDate": "2024-02-02T15:00:00.000Z"
}
```

## Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

## Error Response Format

```json
{
  "error": "Error message here"
}
```

## Notes

1. All dates should be in ISO 8601 format
2. Authentication token expires after 7 days
3. User profile updates must match the authenticated user's ID
4. Role-based permissions are enforced on all protected routes
