/**
 * Basic integration test for MedEcos API
 * Tests the core functionality of the medical ecosystem
 */

const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');

// Test data
let doctorToken, patientToken, pharmacistToken, labTesterToken;
let doctorId, patientId, pharmacistId, labTesterId;
let doctorProfileId, patientProfileId, pharmacistProfileId, labTesterProfileId;

// Setup: Connect to test database
beforeAll(async () => {
  const testDbUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/medecos_test';
  if (mongoose.connection.readyState === 0) {
    await mongoose.connect(testDbUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
  }
});

// Cleanup: Close database connection and drop test data
afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.connection.close();
});

describe('MedEcos API Tests', () => {
  
  // Test 1: Health Check
  test('GET / should return API information', async () => {
    const response = await request(app).get('/');
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('message');
    expect(response.body.message).toBe('MedEcos API');
  });

  // Test 2: Register Doctor
  test('POST /api/auth/register should register a doctor', async () => {
    const doctorData = {
      name: 'Dr. Test Doctor',
      email: 'doctor@test.com',
      password: 'test123',
      userType: 'doctor',
      phone: '1234567890',
      address: 'Test Address',
      additionalInfo: {
        specialization: 'General Medicine',
        licenseNumber: 'DOC001',
        qualifications: ['MBBS'],
        experience: 5,
        consultationFee: 100
      }
    };

    const response = await request(app)
      .post('/api/auth/register')
      .send(doctorData);

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('token');
    expect(response.body.user.email).toBe(doctorData.email);
    expect(response.body.user.userType).toBe('doctor');

    doctorToken = response.body.token;
    doctorId = response.body.user.id;
  });

  // Test 3: Register Patient
  test('POST /api/auth/register should register a patient', async () => {
    const patientData = {
      name: 'Test Patient',
      email: 'patient@test.com',
      password: 'test123',
      userType: 'patient',
      phone: '1234567891',
      address: 'Test Address',
      additionalInfo: {
        dateOfBirth: '1990-01-01',
        gender: 'male',
        bloodGroup: 'O+'
      }
    };

    const response = await request(app)
      .post('/api/auth/register')
      .send(patientData);

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('token');
    patientToken = response.body.token;
    patientId = response.body.user.id;
  });

  // Test 4: Register Pharmacist
  test('POST /api/auth/register should register a pharmacist', async () => {
    const pharmacistData = {
      name: 'Test Pharmacist',
      email: 'pharmacist@test.com',
      password: 'test123',
      userType: 'pharmacist',
      phone: '1234567892',
      address: 'Test Address',
      additionalInfo: {
        pharmacyName: 'Test Pharmacy',
        licenseNumber: 'PHARM001',
        pharmacyAddress: 'Test Pharmacy Address'
      }
    };

    const response = await request(app)
      .post('/api/auth/register')
      .send(pharmacistData);

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('token');
    pharmacistToken = response.body.token;
    pharmacistId = response.body.user.id;
  });

  // Test 5: Register Lab Tester
  test('POST /api/auth/register should register a lab tester', async () => {
    const labTesterData = {
      name: 'Test Lab Tester',
      email: 'labtester@test.com',
      password: 'test123',
      userType: 'lab_tester',
      phone: '1234567893',
      address: 'Test Address',
      additionalInfo: {
        labName: 'Test Lab',
        licenseNumber: 'LAB001',
        labAddress: 'Test Lab Address'
      }
    };

    const response = await request(app)
      .post('/api/auth/register')
      .send(labTesterData);

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('token');
    labTesterToken = response.body.token;
    labTesterId = response.body.user.id;
  });

  // Test 6: Login
  test('POST /api/auth/login should login a user', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'doctor@test.com',
        password: 'test123'
      });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('token');
    expect(response.body.message).toBe('Login successful');
  });

  // Test 7: Get Doctors List
  test('GET /api/doctors should return list of doctors', async () => {
    const response = await request(app)
      .get('/api/doctors')
      .set('Authorization', `Bearer ${doctorToken}`);

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
    expect(response.body.length).toBeGreaterThan(0);
    
    doctorProfileId = response.body[0]._id;
  });

  // Test 8: Get Patients List (Doctor only)
  test('GET /api/patients should return list of patients for doctors', async () => {
    const response = await request(app)
      .get('/api/patients')
      .set('Authorization', `Bearer ${doctorToken}`);

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
    
    patientProfileId = response.body[0]._id;
  });

  // Test 9: Get Pharmacists List
  test('GET /api/pharmacists should return list of pharmacists', async () => {
    const response = await request(app)
      .get('/api/pharmacists')
      .set('Authorization', `Bearer ${pharmacistToken}`);

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
    
    pharmacistProfileId = response.body[0]._id;
  });

  // Test 10: Get Lab Testers List
  test('GET /api/lab-testers should return list of lab testers', async () => {
    const response = await request(app)
      .get('/api/lab-testers')
      .set('Authorization', `Bearer ${labTesterToken}`);

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
    
    labTesterProfileId = response.body[0]._id;
  });

  // Test 11: Unauthorized Access
  test('GET /api/doctors without token should return 401', async () => {
    const response = await request(app).get('/api/doctors');
    expect(response.status).toBe(401);
  });

  // Test 12: Patient cannot access other patients list
  test('GET /api/patients as patient should return 403', async () => {
    const response = await request(app)
      .get('/api/patients')
      .set('Authorization', `Bearer ${patientToken}`);

    expect(response.status).toBe(403);
  });

});

describe('Medical Workflow Tests', () => {
  let appointmentId, prescriptionId, labTestId, pharmacyOrderId;

  // Test 13: Create Appointment
  test('POST /api/appointments should create an appointment', async () => {
    // First get profile IDs
    const doctorsResponse = await request(app)
      .get('/api/doctors')
      .set('Authorization', `Bearer ${doctorToken}`);
    doctorProfileId = doctorsResponse.body[0]._id;

    const patientsResponse = await request(app)
      .get('/api/patients')
      .set('Authorization', `Bearer ${doctorToken}`);
    patientProfileId = patientsResponse.body[0]._id;

    const appointmentData = {
      patient: patientProfileId,
      doctor: doctorProfileId,
      appointmentDate: new Date(Date.now() + 86400000).toISOString(),
      timeSlot: { start: '10:00', end: '10:30' },
      reason: 'Test consultation'
    };

    const response = await request(app)
      .post('/api/appointments')
      .set('Authorization', `Bearer ${patientToken}`)
      .send(appointmentData);

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('_id');
    appointmentId = response.body._id;
  });

  // Test 14: Create Prescription (Doctor only)
  test('POST /api/prescriptions should create a prescription', async () => {
    const prescriptionData = {
      patient: patientProfileId,
      doctor: doctorProfileId,
      diagnosis: 'Test Diagnosis',
      medications: [{
        medicineName: 'Test Medicine',
        dosage: '10mg',
        frequency: 'Once daily',
        duration: '7 days',
        instructions: 'Take with food'
      }]
    };

    const response = await request(app)
      .post('/api/prescriptions')
      .set('Authorization', `Bearer ${doctorToken}`)
      .send(prescriptionData);

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('_id');
    prescriptionId = response.body._id;
  });

  // Test 15: Create Lab Test
  test('POST /api/lab-tests should create a lab test', async () => {
    const labTestersResponse = await request(app)
      .get('/api/lab-testers')
      .set('Authorization', `Bearer ${labTesterToken}`);
    labTesterProfileId = labTestersResponse.body[0]._id;

    const labTestData = {
      patient: patientProfileId,
      doctor: doctorProfileId,
      labTester: labTesterProfileId,
      testName: 'Blood Test',
      scheduledDate: new Date(Date.now() + 86400000).toISOString(),
      price: 50
    };

    const response = await request(app)
      .post('/api/lab-tests')
      .set('Authorization', `Bearer ${doctorToken}`)
      .send(labTestData);

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('_id');
    labTestId = response.body._id;
  });

  // Test 16: Create Pharmacy Order
  test('POST /api/pharmacy-orders should create a pharmacy order', async () => {
    const pharmacistsResponse = await request(app)
      .get('/api/pharmacists')
      .set('Authorization', `Bearer ${pharmacistToken}`);
    pharmacistProfileId = pharmacistsResponse.body[0]._id;

    const orderData = {
      patient: patientProfileId,
      pharmacist: pharmacistProfileId,
      prescription: prescriptionId,
      medications: [{
        medicineName: 'Test Medicine',
        quantity: 30,
        price: 20
      }],
      totalAmount: 20,
      deliveryType: 'pickup'
    };

    const response = await request(app)
      .post('/api/pharmacy-orders')
      .set('Authorization', `Bearer ${patientToken}`)
      .send(orderData);

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('_id');
    pharmacyOrderId = response.body._id;
  });

  // Test 17: Update Lab Test Results (Lab Tester only)
  test('PUT /api/lab-tests/:id should update test results', async () => {
    const updateData = {
      status: 'completed',
      results: {
        findings: 'All normal',
        completedDate: new Date().toISOString()
      }
    };

    const response = await request(app)
      .put(`/api/lab-tests/${labTestId}`)
      .set('Authorization', `Bearer ${labTesterToken}`)
      .send(updateData);

    expect(response.status).toBe(200);
    expect(response.body.status).toBe('completed');
  });

  // Test 18: Update Pharmacy Order Status (Pharmacist only)
  test('PUT /api/pharmacy-orders/:id should update order status', async () => {
    const updateData = {
      status: 'ready'
    };

    const response = await request(app)
      .put(`/api/pharmacy-orders/${pharmacyOrderId}`)
      .set('Authorization', `Bearer ${pharmacistToken}`)
      .send(updateData);

    expect(response.status).toBe(200);
    expect(response.body.status).toBe('ready');
  });

});
