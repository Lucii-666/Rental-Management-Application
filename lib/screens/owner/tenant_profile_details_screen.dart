import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/identity_model.dart';
import '../../models/notification_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

class TenantProfileDetailsScreen extends StatelessWidget {
  final String tenantId;
  const TenantProfileDetailsScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('Tenant Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(tenantId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text('Tenant not found.'));

          final user = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildHeader(context, user),
                const SizedBox(height: 32),
                _buildInfoSection(context, 'Contact Information', [
                  _buildInfoRow(context, Icons.phone_outlined, 'Phone', user.phoneNumber ?? 'Not provided'),
                  _buildInfoRow(context, Icons.email_outlined, 'Email', user.email ?? 'Not provided'),
                ]),
                const SizedBox(height: 24),
                _buildInfoSection(context, 'About', [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      user.bio?.isNotEmpty == true ? user.bio! : 'No bio provided.',
                      style: TextStyle(color: AppTheme.subtext(context), height: 1.5),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildDocumentVerificationSection(context, user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentVerificationSection(BuildContext context, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.softShadow(context)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Identity Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Icon(
                user.isVerified ? Icons.verified : Icons.pending_actions,
                color: user.isVerified ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                user.isVerified ? 'Verified' : 'Pending',
                style: TextStyle(
                  color: user.isVerified ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // Show identity documents submitted by this tenant
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('identity_documents')
                .where('userId', isEqualTo: tenantId)
                .orderBy('uploadedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.subtext(context), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'No documents submitted yet.',
                        style: TextStyle(color: AppTheme.subtext(context)),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final identity = IdentityModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                  return _buildDocumentCard(context, identity);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, IdentityModel doc) {
    Color statusColor;
    String statusLabel;

    switch (doc.status) {
      case IdentityStatus.pending:
        statusColor = Colors.orange;
        statusLabel = 'Pending Review';
      case IdentityStatus.verified:
        statusColor = Colors.green;
        statusLabel = 'Verified';
      case IdentityStatus.rejected:
        statusColor = Colors.red;
        statusLabel = 'Rejected';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document header
          Row(
            children: [
              Icon(Icons.badge_outlined, color: AppTheme.primary(context), size: 20),
              const SizedBox(width: 10),
              Text(
                doc.docType.name.toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text(context)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Document image thumbnail — tap to view full
          GestureDetector(
            onTap: () => _showFullImage(context, doc.fileUrl, doc.docType.name.toUpperCase()),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                doc.fileUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 160,
                    color: AppTheme.surface(context),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: AppTheme.surface(context),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: AppTheme.subtext(context)),
                        const SizedBox(height: 4),
                        Text('Failed to load image', style: TextStyle(color: AppTheme.subtext(context), fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
          // Action buttons for pending documents
          if (doc.status == IdentityStatus.pending) ...[
            const SizedBox(height: 14),
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
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      // Update document status to verified
      await FirebaseFirestore.instance
          .collection('identity_documents')
          .doc(doc.id)
          .update({
        'status': IdentityStatus.verified.name,
        'reviewedBy': ownerId,
        'reviewedAt': DateTime.now().toIso8601String(),
      });

      // Update user's isVerified flag
      await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.userId)
          .update({'is_verified': true});

      // Notify tenant
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
      // Update document status to rejected
      await FirebaseFirestore.instance
          .collection('identity_documents')
          .doc(doc.id)
          .update({
        'status': IdentityStatus.rejected.name,
        'rejectionReason': reason,
        'reviewedBy': ownerId,
        'reviewedAt': DateTime.now().toIso8601String(),
      });

      // Make sure user is NOT verified
      await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.userId)
          .update({'is_verified': false});

      // Notify tenant
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

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppTheme.primary(context).withValues(alpha: 0.1),
          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          child: user.photoUrl == null ? Icon(Icons.person, size: 60, color: AppTheme.primary(context)) : null,
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.secondary(context)),
        ),
        const SizedBox(height: 4),
        Text(
          'Tenant',
          style: TextStyle(color: AppTheme.primary(context), fontWeight: FontWeight.w600, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.softShadow(context)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary(context)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: AppTheme.subtext(context))),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
