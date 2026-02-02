class PatientDetailsModel {
  final String name;
  final String patientId;
  final String dob;
  final String sex;
  final String weight;
  final String height;
  final String regDate;
  final String lastAppointment;
  final String profileImage;
  final List<String> conditions;

  PatientDetailsModel({
    required this.name,
    required this.patientId,
    required this.dob,
    required this.sex,
    required this.weight,
    required this.height,
    required this.regDate,
    required this.lastAppointment,
    required this.profileImage,
    required this.conditions,
  });
}
