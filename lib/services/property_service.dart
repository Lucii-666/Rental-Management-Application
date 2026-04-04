import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/property_model.dart';
import '../models/room_model.dart';
import '../models/join_request_model.dart';
import '../models/maintenance_model.dart';
import '../models/room_request_model.dart';
import 'push_notification_service.dart';
import 'storage_service.dart';
import 'dart:io';
import 'dart:math';

class PropertyService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PushNotificationService _push = PushNotificationService();

  final List<PropertyModel> _properties = [];
  List<PropertyModel> get properties => _properties;

  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Internal helper: save in-app notification + fire push ─────────────────
  Future<void> _notify({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': DateTime.now().toIso8601String(),
      'isRead': false,
    });
    await _push.sendPushNotification(
      targetUserId: userId,
      title: title,
      body: message,
      data: {'type': type},
    );
  }

  // Stream of properties for a specific owner
  Stream<List<PropertyModel>> getPropertiesStream(String ownerId) {
    return _firestore
        .collection('properties')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream for a single property
  Stream<PropertyModel> getPropertyStream(String propertyId) {
    return _firestore
        .collection('properties')
        .doc(propertyId)
        .snapshots()
        .map((doc) => PropertyModel.fromMap(doc.data()!, doc.id));
  }

  // Add a new property
  Future<String?> addProperty(PropertyModel property) async {
    try {
      await _firestore.collection('properties').add(property.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Generate a random 6-character Join Code
  String generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  // Update Join Code for a property
  Future<void> updateJoinCode(String propertyId, int expiryHours) async {
    final code = generateJoinCode();
    final expiry = DateTime.now().add(Duration(hours: expiryHours));

    await _firestore.collection('properties').doc(propertyId).update({
      'joinCode': code,
      'joinCodeExpiry': expiry.toIso8601String(),
    });
  }

  // Room Management
  Future<void> addRoom(RoomModel room) async {
    await _firestore
        .collection('properties')
        .doc(room.propertyId)
        .collection('rooms')
        .add(room.toMap());
  }

  Stream<List<RoomModel>> getRoomsStream(String propertyId) {
    return _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<PropertyModel?> findPropertyByJoinCode(String code) async {
    final snapshot = await _firestore
        .collection('properties')
        .where('joinCode', isEqualTo: code)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    final property = PropertyModel.fromMap(doc.data(), doc.id);

    if (property.joinCodeExpiry != null &&
        property.joinCodeExpiry!.isBefore(DateTime.now())) {
      return null;
    }

    return property;
  }

  // Join Request Management
  Future<String?> sendJoinRequest({
    required String propertyId,
    required String propertyName,
    required String ownerId,
    required String tenantId,
    required String tenantName,
    String? tenantPhone,
  }) async {
    try {
      await _firestore.collection('join_requests').add({
        'propertyId': propertyId,
        'propertyName': propertyName,
        'tenantId': tenantId,
        'tenantName': tenantName,
        'tenantPhone': tenantPhone ?? '',
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'ownerId': ownerId,
      });

      // Notify the owner about the new join request
      await _notify(
        userId: ownerId,
        title: 'New Join Request',
        message: '$tenantName has requested to join $propertyName.',
        type: 'join_request',
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Stream<DocumentSnapshot> getTenantAssociation(String tenantId) {
    return _firestore.collection('users').doc(tenantId).snapshots();
  }

  Stream<List<JoinRequestModel>> getOwnerJoinRequestsStream(String ownerId) {
    return _firestore
        .collection('join_requests')
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JoinRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> handleJoinRequest(String requestId, bool approve) async {
    final status = approve ? 'approved' : 'rejected';
    await _firestore
        .collection('join_requests')
        .doc(requestId)
        .update({'status': status});

    final requestDoc =
        await _firestore.collection('join_requests').doc(requestId).get();
    if (!requestDoc.exists) return;

    final data = requestDoc.data()!;
    final tenantId = data['tenantId'] as String?;
    if (tenantId == null) return;

    if (approve) {
      final propertyId = data['propertyId'];

      // 1. Update User Profile with PropertyId
      await _firestore
          .collection('users')
          .doc(tenantId)
          .update({'propertyId': propertyId});

      // 2. Add to Property Tenants list
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('tenants')
          .doc(tenantId)
          .set({
        'name': data['tenantName'],
        'phone': data['tenantPhone'] ?? '',
        'joinedAt': DateTime.now().toIso8601String(),
        'status': 'active',
        'propertyId': propertyId,
      });

      // 3. Notify tenant — approval + push
      await _notify(
        userId: tenantId,
        title: 'Join Request Approved ✓',
        message: 'You have successfully joined ${data['propertyName']}!',
        type: 'join_request',
      );
    } else {
      // Notify tenant — rejection + push
      await _notify(
        userId: tenantId,
        title: 'Join Request Rejected',
        message: 'Your request to join ${data['propertyName']} was declined.',
        type: 'join_request',
      );
    }
  }

  // Maintenance Request Management
  Stream<List<MaintenanceRequestModel>> getTenantMaintenanceRequestsStream(
      String tenantId) {
    return _firestore
        .collection('maintenance_requests')
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<MaintenanceRequestModel>> getOwnerMaintenanceRequestsStream(
      String ownerId) {
    return _firestore
        .collection('maintenance_requests')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateMaintenanceStatus(String requestId, String status) async {
    final doc = await _firestore
        .collection('maintenance_requests')
        .doc(requestId)
        .get();
    if (!doc.exists) return;

    final tenantId = doc.data()?['tenantId'] as String?;
    final title = doc.data()?['title'] ?? 'your request';
    final ownerId = doc.data()?['ownerId'] as String?;

    await _firestore
        .collection('maintenance_requests')
        .doc(requestId)
        .update({'status': status});

    if (tenantId != null) {
      await _notify(
        userId: tenantId,
        title: 'Maintenance Update',
        message: 'Your request "$title" status changed to: $status.',
        type: 'maintenance_update',
      );
    }

    // Also notify the owner if the tenant submitted the request (status = submitted → owner notified)
    if (status == 'pending' && ownerId != null) {
      await _notify(
        userId: ownerId,
        title: 'New Maintenance Request',
        message: 'A new maintenance request "$title" has been submitted.',
        type: 'maintenance_update',
      );
    }
  }

  Future<String?> submitMaintenanceRequest(MaintenanceRequestModel request,
      {File? imageFile}) async {
    try {
      final docRef = _firestore.collection('maintenance_requests').doc();

      String? imageUrl;
      if (imageFile != null) {
        final storageService = StorageService();
        imageUrl = await storageService.uploadMaintenanceImage(docRef.id, imageFile);
      }

      final finalRequest = request.copyWith(id: docRef.id, imageUrl: imageUrl);
      await docRef.set(finalRequest.toMap());

      // Notify the owner about the new maintenance request
      if (request.ownerId.isNotEmpty) {
        await _notify(
          userId: request.ownerId,
          title: 'New Maintenance Request',
          message:
              '${request.tenantName} submitted a maintenance request: "${request.title}".',
          type: 'maintenance_update',
        );
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Summary Stats
  Future<Map<String, int>> getOwnerStats(String ownerId) async {
    int properties = 0;
    int rooms = 0;
    int tenants = 0;

    final propsSnapshot = await _firestore
        .collection('properties')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    properties = propsSnapshot.docs.length;

    for (var doc in propsSnapshot.docs) {
      final roomsSnapshot = await doc.reference.collection('rooms').get();
      rooms += roomsSnapshot.docs.length;

      final tenantsSnapshot = await doc.reference.collection('tenants').get();
      tenants += tenantsSnapshot.docs.length;
    }

    return {'properties': properties, 'rooms': rooms, 'tenants': tenants};
  }

  // Tenant Management
  Stream<List<Map<String, dynamic>>> getRoomTenantsStream(
      String propertyId, String roomId) {
    return _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('tenants')
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> removeTenantFromRoom(
      String propertyId, String roomId, String tenantId, String reason) async {
    final tenantDoc = await _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('tenants')
        .doc(tenantId)
        .get();

    if (!tenantDoc.exists) return;

    final tenantData = tenantDoc.data()!;
    final propertyDoc =
        await _firestore.collection('properties').doc(propertyId).get();
    final propertyName = propertyDoc.data()?['name'] ?? 'Unknown Property';

    // 1. Add to History
    await _firestore.collection('tenant_history').add({
      ...tenantData,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'roomId': roomId,
      'leftAt': DateTime.now().toIso8601String(),
      'removalReason': reason,
      'ownerId': propertyDoc.data()?['ownerId'],
    });

    // 2. Decrement Room Occupancy
    final roomDoc = await _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .doc(roomId)
        .get();

    if (roomDoc.exists) {
      final currentOcc = roomDoc.data()?['currentOccupancy'] ?? 1;
      await roomDoc.reference
          .update({'currentOccupancy': max(0, currentOcc - 1)});
    }

    // 3. Clear user's propertyId and roomId
    await _firestore.collection('users').doc(tenantId).update({
      'propertyId': null,
      'roomId': null,
    });

    // 4. Notify tenant of removal + push
    final msg = reason.isNotEmpty
        ? 'You have been removed from $propertyName. Reason: $reason'
        : 'You have been removed from $propertyName.';
    await _notify(
      userId: tenantId,
      title: 'Removed from Property',
      message: msg,
      type: 'general',
    );

    // 5. Remove from Active Tenants
    await tenantDoc.reference.delete();
  }

  Stream<List<Map<String, dynamic>>> getOwnerTenantHistoryStream(
      String ownerId) {
    return _firestore
        .collection('tenant_history')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('leftAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<String?> sendRoomRequest({
    required String tenantId,
    required String tenantName,
    required String propertyId,
    required String roomId,
    required String roomNumber,
    required String ownerId,
  }) async {
    try {
      await _firestore.collection('room_requests').add({
        'tenantId': tenantId,
        'tenantName': tenantName,
        'propertyId': propertyId,
        'roomId': roomId,
        'roomNumber': roomNumber,
        'ownerId': ownerId,
        'status': 'pending',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Notify owner about room request + push
      await _notify(
        userId: ownerId,
        title: 'New Room Request',
        message: '$tenantName has requested Room $roomNumber.',
        type: 'room_request',
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Stream<List<RoomRequestModel>> getOwnerRoomRequestsStream(String ownerId) {
    return _firestore
        .collection('room_requests')
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomRequestModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> handleRoomRequest(String requestId, bool approve) async {
    final status = approve ? 'approved' : 'rejected';
    await _firestore
        .collection('room_requests')
        .doc(requestId)
        .update({'status': status});

    final requestDoc =
        await _firestore.collection('room_requests').doc(requestId).get();
    if (!requestDoc.exists) return;

    final data = requestDoc.data()!;
    final tenantId = data['tenantId'] as String?;
    if (tenantId == null) return;

    if (approve) {
      final propertyId = data['propertyId'];
      final roomId = data['roomId'];
      final roomNumber = data['roomNumber'] ?? '';

      // 1. Update User Profile with RoomId
      await _firestore
          .collection('users')
          .doc(tenantId)
          .update({'roomId': roomId});

      // 2. Update Tenant record in property sub-collection
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('tenants')
          .doc(tenantId)
          .update({'roomId': roomId});

      // 3. Increment Room Occupancy
      final roomRef = _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('rooms')
          .doc(roomId);

      await _firestore.runTransaction((transaction) async {
        final roomSnapshot = await transaction.get(roomRef);
        if (roomSnapshot.exists) {
          final current = roomSnapshot.data()?['currentOccupancy'] ?? 0;
          transaction.update(roomRef, {'currentOccupancy': current + 1});
        }
      });

      // 4. Notify tenant — approval + push
      await _notify(
        userId: tenantId,
        title: 'Room Request Approved ✓',
        message: 'You have been assigned to Room $roomNumber.',
        type: 'room_request',
      );
    } else {
      // Notify tenant — rejection + push
      final roomNumber = data['roomNumber'] ?? '';
      await _notify(
        userId: tenantId,
        title: 'Room Request Rejected',
        message: 'Your request for Room $roomNumber was declined.',
        type: 'room_request',
      );
    }
  }

  Stream<List<RoomRequestModel>> getTenantRoomRequestsStream(String tenantId) {
    return _firestore
        .collection('room_requests')
        .where('tenantId', isEqualTo: tenantId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomRequestModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
