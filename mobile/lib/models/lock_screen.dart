class LockScreenData {
  final String id;
  final String title;
  final String description;
  final String bioCode;
  final String mood;
  final DateTime createdAt;
  final bool isActive;

  LockScreenData({
    required this.id,
    required this.title,
    required this.description,
    required this.bioCode,
    required this.mood,
    required this.createdAt,
    required this.isActive,
  });

  factory LockScreenData.fromJson(Map<String, dynamic> json) {
    return LockScreenData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      bioCode: json['bioCode'] ?? '',
      mood: json['mood'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'bioCode': bioCode,
      'mood': mood,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
