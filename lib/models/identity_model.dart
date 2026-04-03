enum IdentityStatus { pending, verified, rejected }
enum IdentityType { aadhaar, pan, license, voterId }

class IdentityModel {
  final String id;
  final String userId;
  final String userName;
  final IdentityType docType;
  final String fileUrl;
  final IdentityStatus status;
  final DateTime uploadedAt;
  final String? rejectionReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  IdentityModel({
    this.id = '',
    required this.userId,
    this.userName = '',
    required this.docType,
    required this.fileUrl,
    this.status = IdentityStatus.pending,
    required this.uploadedAt,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'docType': docType.name,
      'fileUrl': fileUrl,
      'status': status.name,
      'uploadedAt': uploadedAt.toIso8601String(),
      'rejectionReason': rejectionReason,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
    };
  }

  factory IdentityModel.fromMap(Map<String, dynamic> map, String docId) {
    return IdentityModel(
      id: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      docType: IdentityType.values.firstWhere((e) => e.name == map['docType'], orElse: () => IdentityType.aadhaar),
      fileUrl: map['fileUrl'] ?? '',
      status: IdentityStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => IdentityStatus.pending),
      uploadedAt: DateTime.parse(map['uploadedAt'] ?? DateTime.now().toIso8601String()),
      rejectionReason: map['rejectionReason'],
      reviewedBy: map['reviewedBy'],
      reviewedAt: map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt']) : null,
    );
  }
}
