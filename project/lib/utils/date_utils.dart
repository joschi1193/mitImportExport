String formatDate(DateTime date) {
  return '${date.day}.${date.month}.${date.year}';
}

DateTime getStartOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime getEndOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day).add(const Duration(days: 1));
}

bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}
