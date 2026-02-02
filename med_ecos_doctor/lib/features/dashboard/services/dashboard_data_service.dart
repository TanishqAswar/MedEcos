import '../models/appointment_model.dart';
import '../models/patient_details_model.dart';

class DashboardDataService {
  static List<AppointmentModel> getTodayAppointments() {
    return [
      AppointmentModel(
        patientName: 'M.J. Mical',
        patientImage: '👨‍⚕️',
        diagnosis: 'Health Checkup',
        time: '12:00 PM',
        status: 'On Going',
      ),
      AppointmentModel(
        patientName: 'Sanath Deo',
        patientImage: '👨',
        diagnosis: 'Health Checkup',
        time: '12:30 PM',
        status: 'Scheduled',
      ),
      AppointmentModel(
        patientName: 'Loeara Phanj',
        patientImage: '👨‍💼',
        diagnosis: 'Report',
        time: '01:00 PM',
        status: 'Scheduled',
      ),
      AppointmentModel(
        patientName: 'Komola Haris',
        patientImage: '👩',
        diagnosis: 'Common Cold',
        time: '01:30 PM',
        status: 'Scheduled',
      ),
    ];
  }

  static List<AppointmentModel> getAppointmentRequests() {
    return [
      AppointmentModel(
        patientName: 'Maria Sarafat',
        patientImage: '👩‍⚕️',
        diagnosis: 'Cold',
        time: 'Pending',
        status: 'New',
      ),
      AppointmentModel(
        patientName: 'Jhon Deo',
        patientImage: '👨‍💼',
        diagnosis: 'Over swting',
        time: 'Pending',
        status: 'New',
      ),
    ];
  }

  static PatientDetailsModel getNextPatient() {
    return PatientDetailsModel(
      name: 'Sanath Deo',
      patientId: '020092020005',
      dob: '15 January 1989',
      sex: 'Male',
      weight: '85 Kg',
      height: '172 cm',
      regDate: '10 Dec 2021',
      lastAppointment: '15 Dec - 2021',
      profileImage: '👨',
      conditions: ['Asthma', 'Hypertension', 'Fever'],
    );
  }

  static Map<String, double> getPatientReviews() {
    return {
      'Excellent': 0.8,
      'Great': 0.6,
      'Good': 0.4,
      'Average': 0.3,
    };
  }

  static Map<String, int> getPatientSummary() {
    return {
      'New Patients': 450,
      'Old Patients': 800,
      'Total Patients': 2000,
    };
  }
}
