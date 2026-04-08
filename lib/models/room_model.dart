class RoomModel {
  final String id;
  final String propertyId;
  final String roomNumber; // e.g. "101" or "Main Hall"
  final double rentAmount;
  final int maxOccupancy;
  final int currentOccupancy;
  final String description;
  final DateTime createdAt;
  final List<String> imageUrls;
  final List<Map<String, dynamic>> extraFees; // [{name: 'Water Bill', amount: 200.0}, ...]

  RoomModel({
    required this.id,
    required this.propertyId,
    required this.roomNumber,
    required this.rentAmount,
    required this.maxOccupancy,
    this.currentOccupancy = 0,
    this.description = '',
    required this.createdAt,
    this.imageUrls = const [],
    this.extraFees = const [],
  });

  String get status {
    if (currentOccupancy == 0) return 'Available';
    if (currentOccupancy >= maxOccupancy) return 'Full';
    return 'Partially Occupied';
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'roomNumber': roomNumber,
      'rentAmount': rentAmount,
      'maxOccupancy': maxOccupancy,
      'currentOccupancy': currentOccupancy,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'imageUrls': imageUrls,
      'extraFees': extraFees,
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map, String docId) {
    return RoomModel(
      id: docId,
      propertyId: map['propertyId'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      rentAmount: (map['rentAmount'] ?? 0.0).toDouble(),
      maxOccupancy: map['maxOccupancy'] ?? 1,
      currentOccupancy: map['currentOccupancy'] ?? 0,
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      extraFees: List<Map<String, dynamic>>.from(
        (map['extraFees'] ?? []).map((e) => Map<String, dynamic>.from(e)),
      ),
    );
  }
}
