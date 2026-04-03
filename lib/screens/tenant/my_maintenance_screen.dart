import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/maintenance_model.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../utils/app_theme.dart';
import 'report_maintenance_screen.dart';

class MyMaintenanceScreen extends StatelessWidget {
  const MyMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final propertyService = Provider.of<PropertyService>(context, listen: false);
    final tenantId = authService.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('Maintenance', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportMaintenanceScreen()),
        ),
        backgroundColor: AppTheme.primary(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Request', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<MaintenanceRequestModel>>(
        stream: propertyService.getTenantMaintenanceRequestsStream(tenantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.build_circle_outlined, size: 80, color: AppTheme.subtext(context).withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'No maintenance requests yet',
                      style: TextStyle(fontSize: 16, color: AppTheme.subtext(context)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the button below to report an issue in your room.',
                      style: TextStyle(fontSize: 13, color: AppTheme.subtext(context)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Group by status: pending/inProgress first, resolved last
          final active = requests.where((r) => r.status != MaintenanceStatus.resolved).toList();
          final resolved = requests.where((r) => r.status == MaintenanceStatus.resolved).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              if (active.isNotEmpty) ...[
                _buildSectionHeader(context, 'Active (${active.length})'),
                const SizedBox(height: 12),
                ...active.map((r) => _buildRequestCard(context, r)),
                const SizedBox(height: 24),
              ],
              if (resolved.isNotEmpty) ...[
                _buildSectionHeader(context, 'Resolved (${resolved.length})'),
                const SizedBox(height: 12),
                ...resolved.map((r) => _buildRequestCard(context, r)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.secondary(context)),
    );
  }

  Widget _buildRequestCard(BuildContext context, MaintenanceRequestModel request) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (request.status) {
      case MaintenanceStatus.pending:
        statusColor = Colors.orange;
        statusLabel = 'Pending';
        statusIcon = Icons.hourglass_top_rounded;
      case MaintenanceStatus.inProgress:
        statusColor = Colors.blue;
        statusLabel = 'In Progress';
        statusIcon = Icons.construction_rounded;
      case MaintenanceStatus.resolved:
        statusColor = Colors.green;
        statusLabel = 'Resolved';
        statusIcon = Icons.check_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [AppTheme.softShadow(context)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar at top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  _formatDate(request.createdAt),
                  style: TextStyle(color: AppTheme.subtext(context), fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.text(context)),
                ),
                const SizedBox(height: 6),
                Text(
                  request.description,
                  style: TextStyle(color: AppTheme.subtext(context), fontSize: 13, height: 1.4),
                ),
                // Image thumbnail if present
                if (request.imageUrl != null && request.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showFullImage(context, request.imageUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        request.imageUrl!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
                // Progress timeline for in-progress
                if (request.status == MaintenanceStatus.inProgress) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.construction_rounded, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Text('Your owner is working on this.', style: TextStyle(color: Colors.blue, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }
}
