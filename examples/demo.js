#!/usr/bin/env node

/**
 * Example script demonstrating the Medical Ecosystem workflow
 * 
 * This script shows:
 * 1. User registration for all user types
 * 2. Patient booking an appointment
 * 3. Doctor creating a prescription
 * 4. Patient ordering medication from pharmacy
 * 5. Doctor ordering lab tests
 * 6. Lab tester updating test results
 */

const axios = require('axios');

const API_URL = 'http://localhost:3000/api';

// Helper function for API calls
async function apiCall(method, endpoint, data = null, token = null) {
  const config = {
    method,
    url: `${API_URL}${endpoint}`,
    headers: {}
  };

  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  if (data) {
    config.data = data;
    config.headers['Content-Type'] = 'application/json';
  }

  try {
    const response = await axios(config);
    return response.data;
  } catch (error) {
    console.error(`Error on ${method} ${endpoint}:`, error.response?.data || error.message);
    throw error;
  }
}

async function main() {
  console.log('🏥 MedEcos - Medical Ecosystem Demo\n');
  console.log('====================================\n');

  try {
    // Step 1: Register a Doctor
    console.log('1️⃣  Registering Doctor...');
    const doctorData = {
      name: 'Dr. Sarah Johnson',
      email: 'sarah.johnson@hospital.com',
      password: 'doctor123',
      userType: 'doctor',
      phone: '555-0101',
      address: '123 Medical Center, Health City',
      additionalInfo: {
        specialization: 'Cardiology',
        licenseNumber: 'DOC2024001',
        qualifications: ['MBBS', 'MD Cardiology', 'FACC'],
        experience: 15,
        consultationFee: 150,
        availability: [
          { day: 'Monday', startTime: '09:00', endTime: '17:00' },
          { day: 'Wednesday', startTime: '09:00', endTime: '17:00' },
          { day: 'Friday', startTime: '09:00', endTime: '17:00' }
        ]
      }
    };
    const doctorResponse = await apiCall('POST', '/auth/register', doctorData);
    const doctorToken = doctorResponse.token;
    const doctorId = doctorResponse.user.id;
    console.log('✅ Doctor registered:', doctorResponse.user.name);
    console.log('   Token:', doctorToken.substring(0, 20) + '...\n');

    // Step 2: Register a Patient
    console.log('2️⃣  Registering Patient...');
    const patientData = {
      name: 'John Smith',
      email: 'john.smith@email.com',
      password: 'patient123',
      userType: 'patient',
      phone: '555-0202',
      address: '456 Oak Street, Health City',
      additionalInfo: {
        dateOfBirth: '1985-06-15',
        gender: 'male',
        bloodGroup: 'O+',
        allergies: ['Penicillin'],
        emergencyContact: {
          name: 'Jane Smith',
          phone: '555-0203',
          relationship: 'Spouse'
        }
      }
    };
    const patientResponse = await apiCall('POST', '/auth/register', patientData);
    const patientToken = patientResponse.token;
    const patientId = patientResponse.user.id;
    console.log('✅ Patient registered:', patientResponse.user.name);
    console.log('   Token:', patientToken.substring(0, 20) + '...\n');

    // Step 3: Register a Pharmacist
    console.log('3️⃣  Registering Pharmacist...');
    const pharmacistData = {
      name: 'Michael Brown',
      email: 'michael.brown@pharmacy.com',
      password: 'pharmacist123',
      userType: 'pharmacist',
      phone: '555-0303',
      address: '789 Pharmacy Lane, Health City',
      additionalInfo: {
        pharmacyName: 'HealthPlus Pharmacy',
        licenseNumber: 'PHARM2024001',
        pharmacyAddress: '789 Pharmacy Lane, Health City',
        operatingHours: {
          open: '08:00',
          close: '22:00'
        },
        servicesOffered: ['Prescription Filling', 'OTC Medications', 'Health Consultations']
      }
    };
    const pharmacistResponse = await apiCall('POST', '/auth/register', pharmacistData);
    const pharmacistToken = pharmacistResponse.token;
    const pharmacistId = pharmacistResponse.user.id;
    console.log('✅ Pharmacist registered:', pharmacistResponse.user.name);
    console.log('   Pharmacy:', pharmacistData.additionalInfo.pharmacyName, '\n');

    // Step 4: Register a Lab Tester
    console.log('4️⃣  Registering Lab Tester...');
    const labTesterData = {
      name: 'Emily Chen',
      email: 'emily.chen@diagnostics.com',
      password: 'labtester123',
      userType: 'lab_tester',
      phone: '555-0404',
      address: '321 Lab Drive, Health City',
      additionalInfo: {
        labName: 'MediDiagnostics Lab',
        licenseNumber: 'LAB2024001',
        labAddress: '321 Lab Drive, Health City',
        operatingHours: {
          open: '07:00',
          close: '19:00'
        },
        testsAvailable: [
          { testName: 'Complete Blood Count', testCode: 'CBC001', price: 50, duration: '24 hours' },
          { testName: 'Lipid Profile', testCode: 'LIP001', price: 75, duration: '24 hours' },
          { testName: 'Blood Glucose', testCode: 'GLU001', price: 30, duration: '2 hours' }
        ],
        accreditations: ['CAP', 'CLIA', 'ISO 15189']
      }
    };
    const labTesterResponse = await apiCall('POST', '/auth/register', labTesterData);
    const labTesterToken = labTesterResponse.token;
    const labTesterId = labTesterResponse.user.id;
    console.log('✅ Lab Tester registered:', labTesterResponse.user.name);
    console.log('   Lab:', labTesterData.additionalInfo.labName, '\n');

    console.log('====================================\n');
    console.log('📋 Starting Medical Workflow...\n');
    console.log('====================================\n');

    // Get the doctor's profile ID
    const doctors = await apiCall('GET', '/doctors', null, doctorToken);
    const doctorProfileId = doctors.find(d => d.userId._id === doctorId)?._id;

    // Get the patient's profile ID
    const patients = await apiCall('GET', '/patients', null, doctorToken);
    const patientProfileId = patients.find(p => p.userId._id === patientId)?._id;

    // Get the pharmacist's profile ID
    const pharmacists = await apiCall('GET', '/pharmacists', null, pharmacistToken);
    const pharmacistProfileId = pharmacists.find(p => p.userId._id === pharmacistId)?._id;

    // Get the lab tester's profile ID
    const labTesters = await apiCall('GET', '/lab-testers', null, labTesterToken);
    const labTesterProfileId = labTesters.find(l => l.userId._id === labTesterId)?._id;

    // Step 5: Patient books an appointment
    console.log('5️⃣  Patient booking appointment with doctor...');
    const appointmentDate = new Date();
    appointmentDate.setDate(appointmentDate.getDate() + 7);
    const appointmentData = {
      patient: patientProfileId,
      doctor: doctorProfileId,
      appointmentDate: appointmentDate.toISOString(),
      timeSlot: {
        start: '10:00',
        end: '10:30'
      },
      reason: 'Regular checkup and chest pain evaluation'
    };
    const appointment = await apiCall('POST', '/appointments', appointmentData, patientToken);
    console.log('✅ Appointment booked for:', appointmentDate.toLocaleDateString());
    console.log('   Time:', appointmentData.timeSlot.start, '-', appointmentData.timeSlot.end, '\n');

    // Step 6: Doctor creates a prescription
    console.log('6️⃣  Doctor creating prescription after consultation...');
    const prescriptionData = {
      patient: patientProfileId,
      doctor: doctorProfileId,
      appointment: appointment._id,
      diagnosis: 'Mild Hypertension',
      medications: [
        {
          medicineName: 'Lisinopril',
          dosage: '10mg',
          frequency: 'Once daily',
          duration: '30 days',
          instructions: 'Take in the morning with food'
        },
        {
          medicineName: 'Aspirin',
          dosage: '81mg',
          frequency: 'Once daily',
          duration: '30 days',
          instructions: 'Take with dinner'
        }
      ],
      notes: 'Follow up in 4 weeks. Monitor blood pressure daily.'
    };
    const prescription = await apiCall('POST', '/prescriptions', prescriptionData, doctorToken);
    console.log('✅ Prescription created');
    console.log('   Diagnosis:', prescriptionData.diagnosis);
    console.log('   Medications:', prescriptionData.medications.length, '\n');

    // Step 7: Patient orders medication from pharmacy
    console.log('7️⃣  Patient ordering medication from pharmacy...');
    const pharmacyOrderData = {
      patient: patientProfileId,
      pharmacist: pharmacistProfileId,
      prescription: prescription._id,
      medications: [
        { medicineName: 'Lisinopril 10mg', quantity: 30, price: 15 },
        { medicineName: 'Aspirin 81mg', quantity: 30, price: 5 }
      ],
      totalAmount: 20,
      deliveryType: 'pickup',
      deliveryAddress: patientData.address
    };
    const order = await apiCall('POST', '/pharmacy-orders', pharmacyOrderData, patientToken);
    console.log('✅ Pharmacy order placed');
    console.log('   Order ID:', order._id);
    console.log('   Total Amount: $' + order.totalAmount, '\n');

    // Step 8: Pharmacist updates order status
    console.log('8️⃣  Pharmacist processing order...');
    const orderUpdate = {
      status: 'ready'
    };
    await apiCall('PUT', `/pharmacy-orders/${order._id}`, orderUpdate, pharmacistToken);
    console.log('✅ Order ready for pickup\n');

    // Step 9: Doctor orders lab tests
    console.log('9️⃣  Doctor ordering lab tests...');
    const testDate = new Date();
    testDate.setDate(testDate.getDate() + 2);
    const labTestData = {
      patient: patientProfileId,
      doctor: doctorProfileId,
      labTester: labTesterProfileId,
      testName: 'Lipid Profile',
      testCode: 'LIP001',
      scheduledDate: testDate.toISOString(),
      price: 75,
      notes: 'Fasting required - 12 hours'
    };
    const labTest = await apiCall('POST', '/lab-tests', labTestData, doctorToken);
    console.log('✅ Lab test scheduled');
    console.log('   Test:', labTestData.testName);
    console.log('   Date:', testDate.toLocaleDateString(), '\n');

    // Step 10: Lab tester updates test results
    console.log('🔟 Lab tester updating test results...');
    const testResults = {
      status: 'completed',
      results: {
        findings: 'Total Cholesterol: 195 mg/dL (Normal), LDL: 120 mg/dL (Normal), HDL: 55 mg/dL (Normal), Triglycerides: 100 mg/dL (Normal)',
        reportUrl: 'https://example.com/reports/lipid-profile-123.pdf',
        completedDate: new Date().toISOString()
      }
    };
    await apiCall('PUT', `/lab-tests/${labTest._id}`, testResults, labTesterToken);
    console.log('✅ Test results updated');
    console.log('   Status:', testResults.status);
    console.log('   Findings:', testResults.results.findings.substring(0, 60) + '...\n');

    console.log('====================================\n');
    console.log('✨ Medical Ecosystem Demo Complete!\n');
    console.log('====================================\n');
    console.log('Summary:');
    console.log('- 4 users registered (Doctor, Patient, Pharmacist, Lab Tester)');
    console.log('- 1 appointment scheduled');
    console.log('- 1 prescription created');
    console.log('- 1 pharmacy order placed');
    console.log('- 1 lab test ordered and completed');
    console.log('\n🎉 All healthcare workflows working successfully!\n');

  } catch (error) {
    console.error('\n❌ Error during demo:', error.message);
    process.exit(1);
  }
}

// Check if server is running
async function checkServer() {
  try {
    await axios.get('http://localhost:3000');
    return true;
  } catch (error) {
    return false;
  }
}

// Main execution
(async () => {
  const serverRunning = await checkServer();
  if (!serverRunning) {
    console.error('❌ Server is not running. Please start the server first:');
    console.error('   npm start\n');
    process.exit(1);
  }

  await main();
})();
