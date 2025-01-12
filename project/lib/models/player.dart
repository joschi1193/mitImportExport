class Player {
  final String name;
  final bool isGuest;

  const Player({
    required this.name,
    this.isGuest = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isGuest': isGuest,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'],
      isGuest: json['isGuest'] ?? false,
    );
  }
}
