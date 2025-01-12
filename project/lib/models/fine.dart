class Fine {
  final String name;
  final double amount;
  final DateTime date;
  final String description;
  bool isPaid;

  Fine({
    required this.name,
    required this.amount,
    required this.date,
    required this.description,
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'isPaid': isPaid,
    };
  }

  factory Fine.fromJson(Map<String, dynamic> json) {
    return Fine(
      name: json['name'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      description: json['description'],
      isPaid: json['isPaid'] ?? false,
    );
  }
}