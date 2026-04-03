import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
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
                _buildInfoSection(context, 'Verification Status', [
                  Row(
                    children: [
                      Icon(
                        user.isVerified ? Icons.verified : Icons.pending_actions,
                        color: user.isVerified ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        user.isVerified ? 'Identity Verified' : 'Verification Pending',
                        style: TextStyle(
                          color: user.isVerified ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
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
