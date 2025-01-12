import '../models/fine.dart';
import '../models/attendance.dart';
import 'date_utils.dart';

double calculateTotalAmount(List<Fine> fines) {
  return fines.fold(0, (sum, fine) => sum + fine.amount);
}

double calculateUnpaidAmount(List<Fine> fines, String name) {
  return fines
      .where((fine) => fine.name == name && !fine.isPaid)
      .fold(0, (sum, fine) => sum + fine.amount);
}

double calculateAverageFine(List<Fine> fines, List<Attendance> attendance) {
  final today = DateTime.now();
  final todayStart = getStartOfDay(today);
  final todayEnd = getEndOfDay(today);

  // Get today's fines excluding base fines and previous averages
  final todaysFines = fines
      .where((fine) =>
          fine.date.isAfter(todayStart) &&
          fine.date.isBefore(todayEnd) &&
          fine.description != 'Grundbetrag' &&
          !fine.description.contains('Durchschnitt'))
      .toList();

  // Get count of present and late players
  final presentAndLatePlayers = attendance
      .where((a) =>
          a.date.isAfter(todayStart) &&
          a.date.isBefore(todayEnd) &&
          (a.status == AttendanceStatus.present ||
              a.status == AttendanceStatus.late))
      .length;

  // If no one is present or late, return 0
  if (presentAndLatePlayers == 0) return 0;

  // Calculate total fines for the day
  final totalFines = calculateTotalAmount(todaysFines);

  // Return average (total fines divided by number of present and late players)
  return totalFines / presentAndLatePlayers;
}

List<String> getPresentPlayers(List<Attendance> attendance) {
  final today = DateTime.now();
  final todayStart = getStartOfDay(today);
  final todayEnd = getEndOfDay(today);

  return attendance
      .where((a) =>
          a.date.isAfter(todayStart) &&
          a.date.isBefore(todayEnd) &&
          (a.status == AttendanceStatus.present ||
              a.status == AttendanceStatus.late))
      .map((a) => a.name)
      .toList();
}
