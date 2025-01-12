String formatCurrency(double amount) {
  return '${amount.toStringAsFixed(2)} €';
}

String formatStatus(String status) {
  return status.split('.').last;
}