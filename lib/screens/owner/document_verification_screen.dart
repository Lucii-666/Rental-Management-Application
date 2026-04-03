import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/identity_model.dart';
import '../../models/notification_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

class DocumentVerificationScreen extends StatelessWidget {
  const DocumentVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final ownerId = authService.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('Document Verification', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _buildDocumentsList(context, ownerId),
    );
  }

  /// We get all tenants belonging to this owner's properties, then
  /// fetch their identity documents.
  Widget _buildDocumentsList(BuildContext context, String ownerId) {
    return StreamBuilder<QuerySnapshot>(
      // Step 1: Get all properties owned by this user
      stream: FirebaseFirestore.instance
          .collection('properties')
          .where('ownerId', isEqualTo: ownerId)
          .snapshots(),
      builder: (context, propSnapshot) {
        if (propSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!propSnapshot.hasData || propSnapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No properties found.');
        }

        final propertyIds = propSnapshot.data!.docs.map((d) => d.id).toList();

        // Step 2: Get all tenants across all properties
        return _buildTenantDocuments(context, propertyIds);
      },
    );
  }

  Widget _buildTenantDocuments(BuildContext context, List<String> propertyIds) {
    // We need tenant IDs from all properties. We'll gather them from
    // the tenants subcollection of each property.
    return FutureBuilder<List<String>>(
      future: _getAllTenantIds(propertyIds),
      builder: (context, tenantSnapshot) {
        if (tenantSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tenantIds = tenantSnapshot.data ?? [];

        if (tenantIds.isEmpty) {
          return _buildEmptyState('No tenants found in your properties.');
        }

        // Step 3: Query identity_documents for these tenant IDs
        // Firestore 'whereIn' supports up to 30 values per query
        // We'll batch if needed, but typically < 30 tenants
        final batchIds = tenantIds.length > 30 ? tenantIds.sublist(0, 30) : tenantIds;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('identity_documents')
              .where('userId', whereIn: batchIds)
              .snapshots(),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (docSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error loading documents: ${docSnapshot.error}',
                    style: TextStyle(color: AppTheme.subtext(context)),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (!docSnapshot.hasData || docSnapshot.data!.docs.isEmpty) {
              return _buildEmptyState('No documents submitted by tenants yet.');
            }

            final docs = docSnapshot.data!.docs.map((d) {
              return IdentityModel.fromMap(
                d.data() as Map<String, dynamic>,
                d.id,
              );
            }).toList();

            // Sort: pending first, then by uploadedAt descending
            docs.sort((a, b) {
              if (a.status == IdentityStatus.pending && b.status != IdentityStatus.pending) return -1;
              if (a.status != IdentityStatus.pending && b.status == IdentityStatus.pending) return 1;
              return b.uploadedAt.compareTo(a.uploadedAt);
            });

            final pendingDocs = docs.where((d) => d.status == IdentityStatus.pending).toList();
            final reviewedDocs = docs.where((d) => d.status != IdentityStatus.pending).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary banner
                  _buildSummaryBanner(context, pendingDocs.length, reviewedDocs.length),
                  const SizedBox(height: 24),

                  if (pendingDocs.isNotEmpty) ...[
                    Text(
                      'Pending Review (${pendingDocs.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...pendingDocs.map((doc) => _buildDocumentCard(context, doc)),
                    const SizedBox(height: 24),
                  ],

                  if (reviewedDocs.isNotEmpty) ...[
                    Text(
                      'Reviewed (${reviewedDocs.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...reviewedDocs.map((doc) => _buildDocumentCard(context, doc)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<String>> _getAllTenantIds(List<String> propertyIds) async {
    final Set<String> tenantIds = {};

    for (final propId in propertyIds) {
      final tenantsSnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .doc(propId)
          .collection('tenants')
          .get();

      for (final doc in tenantsSnapshot.docs) {
        tenantIds.add(doc.id);
      }
    }

    return tenantIds.toList();
  }

  Widget _buildSummaryBanner(BuildContext context, int pending, int reviewed) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary(context), AppTheme.primary(context).withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Identity Verification',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pending pending • $reviewed reviewed',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          if (pending > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pending',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, IdentityModel doc) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (doc.status) {
      case IdentityStatus.pending:
        statusColor = Colors.orange;
        statusLabel = 'Pending Review';
        statusIcon = Icons.hourglass_top_rounded;
      case IdentityStatus.verified:
        statusColor = Colors.green;
        statusLabel = 'Verified';
        statusIcon = Icons.check_circle_rounded;
      case IdentityStatus.rejected:
        statusColor = Colors.red;
        statusLabel = 'Rejected';
        statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.softShadow(context)],
        border: doc.status == IdentityStatus.pending
            ? Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with tenant name and status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary(context).withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: AppTheme.primary(context), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.userName.isNotEmpty ? doc.userName : 'Tenant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doc.docType.name.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.subtext(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Document image
          GestureDetector(
            onTap: () => _showFullImage(context, doc.fileUrl, doc.docType.name.toUpperCase()),
            child: ClipRRect(
              child: Image.network(
                doc.fileUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 180,
                    color: AppTheme.surface(context),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: AppTheme.surface(context),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: AppTheme.subtext(context), size: 40),
                        const SizedBox(height: 8),
                        Text('Failed to load image', style: TextStyle(color: AppTheme.subtext(context), fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Footer info and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uploaded ${_formatDate(doc.uploadedAt)}',
                  style: TextStyle(color: AppTheme.subtext(context), fontSize: 12),
                ),
                if (doc.status == IdentityStatus.rejected && doc.rejectionReason != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Reason: ${doc.rejectionReason}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],

                // Action buttons only for pending documents
                if (doc.status == IdentityStatus.pending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(context, doc),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveDocument(context, doc),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Verify'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 300,
                    color: AppTheme.surface(context),
                    child: const Center(child: Text('Failed to load image')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveDocument(BuildContext context, IdentityModel doc) async {
    final ownerId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final scout = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance
          .collection('identity_documents')
          .doc(doc.id)
          .update({
        'status': IdentityStatus.verified.name,
        'reviewedBy': ownerId,
        'reviewedAt': DateTime.now().toIso8601String(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.userId)
          .update({'is_verified': true});

      await notificationService.sendNotification(
        NotificationModel(
          id: '',
          userId: doc.userId,
          title: 'Identity Verified',
          message: 'Your ${doc.docType.name.toUpperCase()} document has been verified by your property owner.',
          type: 'identity_verification',
          createdAt: DateTime.now(),
        ),
      );

      scout.showSnackBar(
        const SnackBar(content: Text('Document verified successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      scout.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRejectDialog(BuildContext context, IdentityModel doc) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.card(context),
        title: const Text('Reject Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for rejecting this ${doc.docType.name.toUpperCase()} document.',
              style: TextStyle(color: AppTheme.subtext(context)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Image is blurry, wrong document type...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              _rejectDocument(context, doc, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectDocument(BuildContext context, IdentityModel doc, String reason) async {
    final ownerId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final scout = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance
          .collection('identity_documents')
          .doc(doc.id)
          .update({
        'status': IdentityStatus.rejected.name,
        'rejectionReason': reason,
        'reviewedBy': ownerId,
        'reviewedAt': DateTime.now().toIso8601String(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.userId)
          .update({'is_verified': false});

      await notificationService.sendNotification(
        NotificationModel(
          id: '',
          userId: doc.userId,
          title: 'Document Rejected',
          message: 'Your ${doc.docType.name.toUpperCase()} document was rejected. Reason: $reason. Please upload a new document.',
          type: 'identity_verification',
          createdAt: DateTime.now(),
        ),
      );

      scout.showSnackBar(
        const SnackBar(content: Text('Document rejected. Tenant has been notified.'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      scout.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
