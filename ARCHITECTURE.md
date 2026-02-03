# MedEcos System Architecture

## Overview

MedEcos is a comprehensive medical ecosystem that connects four primary stakeholders in the healthcare system.

## System Components

### User Types

```
┌─────────────────────────────────────────────────────────────────┐
│                         MedEcos Platform                         │
└─────────────────────────────────────────────────────────────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
        ┌───────▼──────┐ ┌─────▼─────┐ ┌──────▼──────┐
        │   Doctors    │ │  Patients │ │ Pharmacists │
        └──────────────┘ └───────────┘ └─────────────┘
                │               │               │
                └───────────────┼───────────────┘
                                │
                        ┌───────▼────────┐
                        │  Lab Testers   │
                        └────────────────┘
```

### Core Interactions

```
┌──────────┐                                      ┌──────────┐
│ Patient  │────────── Appointments ─────────────>│  Doctor  │
│          │<─────────── Schedules ───────────────│          │
└──────────┘                                      └──────────┘
     │                                                  │
     │                                                  │
     │ Orders                                    Creates│
     │ Medications                            Prescription
     │                                                  │
     ▼                                                  ▼
┌──────────┐                                      ┌──────────┐
│Pharmacist│<─────── Prescription ────────────────│  System  │
│          │                                      │          │
└──────────┘                                      └──────────┘
     │                                                  │
     │                                                  │
     │ Fulfills                                  Orders │
     │ Orders                                   Lab Test│
     │                                                  │
     ▼                                                  ▼
┌──────────┐                                      ┌──────────┐
│ Patient  │<────────── Results ──────────────────│Lab Tester│
│          │                                      │          │
└──────────┘                                      └──────────┘
```

## Technology Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB
- **ODM**: Mongoose
- **Authentication**: JWT (JSON Web Tokens)
- **Password Hashing**: bcryptjs

### API Design
- RESTful API architecture
- Role-based access control (RBAC)
- Token-based authentication

## Data Models

### User Models

#### Base User
- Common fields for all user types
- Encrypted password storage
- User type identification

#### Doctor Profile
- Specialization and qualifications
- License information
- Availability schedule
- Consultation fees

#### Patient Profile
- Medical history
- Allergies
- Emergency contacts
- Demographics

#### Pharmacist Profile
- Pharmacy information
- Operating hours
- Services offered

#### Lab Tester Profile
- Lab information
- Available tests
- Accreditations

### Interaction Models

#### Appointments
- Patient-Doctor scheduling
- Status tracking
- Appointment notes

#### Prescriptions
- Medication details
- Dosage and frequency
- Diagnosis information

#### Lab Tests
- Test requests
- Results storage
- Status updates

#### Pharmacy Orders
- Medication orders
- Delivery options
- Order tracking

## API Structure

```
/api
├── /auth
│   ├── POST /register    (Public)
│   └── POST /login       (Public)
│
├── /doctors
│   ├── GET  /            (Authenticated)
│   ├── GET  /:id         (Authenticated)
│   └── PUT  /:id         (Doctor only)
│
├── /patients
│   ├── GET  /            (Doctor only)
│   ├── GET  /:id         (Authenticated)
│   └── PUT  /:id         (Patient only)
│
├── /pharmacists
│   ├── GET  /            (Authenticated)
│   ├── GET  /:id         (Authenticated)
│   └── PUT  /:id         (Pharmacist only)
│
├── /lab-testers
│   ├── GET  /            (Authenticated)
│   ├── GET  /:id         (Authenticated)
│   └── PUT  /:id         (Lab Tester only)
│
├── /appointments
│   ├── POST   /          (Patient only)
│   ├── GET    /          (Authenticated, filtered by user)
│   ├── PUT    /:id       (Authenticated)
│   └── DELETE /:id       (Patient only)
│
├── /prescriptions
│   ├── POST /            (Doctor only)
│   ├── GET  /            (Authenticated, filtered by user)
│   ├── GET  /:id         (Authenticated)
│   └── PUT  /:id         (Doctor/Pharmacist)
│
├── /lab-tests
│   ├── POST /            (Doctor/Patient)
│   ├── GET  /            (Authenticated, filtered by user)
│   ├── GET  /:id         (Authenticated)
│   └── PUT  /:id         (Lab Tester only)
│
└── /pharmacy-orders
    ├── POST /            (Patient only)
    ├── GET  /            (Authenticated, filtered by user)
    ├── GET  /:id         (Authenticated)
    └── PUT  /:id         (Pharmacist only)
```

## Security Features

1. **Authentication**
   - JWT token-based authentication
   - 7-day token expiration
   - Secure password hashing with bcryptjs

2. **Authorization**
   - Role-based access control
   - Endpoint-level permission checks
   - User-specific data filtering

3. **Data Protection**
   - Password hashing before storage
   - Token validation on protected routes
   - Input validation

## Workflow Examples

### 1. Patient Consultation Flow
```
Patient → Books Appointment → Doctor
       ← Confirms Appointment ←
       → Attends Consultation →
       ← Receives Prescription ←
```

### 2. Medication Order Flow
```
Patient → Places Order → Pharmacist
       ← Order Status ←
       → Pickup/Delivery
```

### 3. Lab Test Flow
```
Doctor → Orders Test → Lab Tester
                      ↓
Patient → Sample Collection
                      ↓
Lab Tester → Processes Test
          → Uploads Results
                      ↓
Doctor/Patient ← View Results
```

## Scalability Considerations

- Modular architecture allows independent scaling of components
- Database indexing on frequently queried fields
- Stateless authentication (JWT) enables horizontal scaling
- RESTful design supports caching strategies

## Future Enhancements

- Real-time notifications
- Video consultation integration
- Payment gateway integration
- Electronic health records (EHR) integration
- Mobile application
- Analytics dashboard
- Multi-language support
- Telemedicine features
