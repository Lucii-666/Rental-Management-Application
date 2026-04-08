class PropertyModel {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final String city;
  final String description;
  final int? floors;
  final String? notes;
  final String? joinCode;
  final DateTime? joinCodeExpiry;
  final DateTime createdAt;
  final List<String> imageUrls;

  PropertyModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.city,
    required this.description,
    this.floors,
    this.notes,
    this.joinCode,
    this.joinCodeExpiry,
    required this.createdAt,
    this.imageUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'city': city,
      'description': description,
      'floors': floors,
      'notes': notes,
      'joinCode': joinCode,
      'joinCodeExpiry': joinCodeExpiry?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'imageUrls': imageUrls,
    };
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PropertyModel(
      id: documentId,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      description: map['description'] ?? '',
      floors: map['floors'],
      notes: map['notes'],
      joinCode: map['joinCode'],
      joinCodeExpiry: map['joinCodeExpiry'] != null
          ? DateTime.parse(map['joinCodeExpiry'])
          : null,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }
}
