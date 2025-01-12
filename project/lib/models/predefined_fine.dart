class PredefinedFine {
  final String name;
  final double amount;
  final bool isSpecial;
  final bool isCustomAmount;

  const PredefinedFine({
    required this.name,
    required this.amount,
    this.isSpecial = false,
    this.isCustomAmount = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'isSpecial': isSpecial,
      'isCustomAmount': isCustomAmount,
    };
  }

  factory PredefinedFine.fromJson(Map<String, dynamic> json) {
    return PredefinedFine(
      name: json['name'],
      amount: json['amount'],
      isSpecial: json['isSpecial'] ?? false,
      isCustomAmount: json['isCustomAmount'] ?? false,
    );
  }
}

class PredefinedFines {
  static const List<PredefinedFine> fines = [
    PredefinedFine(name: 'Runde verloren', amount: 3.0),
    PredefinedFine(name: 'Schlafen', amount: 1.0),
    PredefinedFine(name: 'Würfel fallen lassen', amount: 1.0),
    PredefinedFine(name: 'Getränk umgekippt', amount: 2.0),
    PredefinedFine(name: 'Schock Hand', amount: 1.0, isSpecial: true),
    PredefinedFine(name: 'Zu Spät', amount: 0.0, isCustomAmount: true),
  ];
}
