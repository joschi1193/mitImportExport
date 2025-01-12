class Settings {
  final double baseFineAmount;
  final double previousYearsBalance;

  const Settings({
    this.baseFineAmount = 15.0,
    this.previousYearsBalance = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'baseFineAmount': baseFineAmount,
      'previousYearsBalance': previousYearsBalance,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      baseFineAmount: json['baseFineAmount'] ?? 15.0,
      previousYearsBalance: json['previousYearsBalance'] ?? 0.0,
    );
  }
}
