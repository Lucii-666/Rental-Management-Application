import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/maintenance_model.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../utils/app_theme.dart';

class MaintenanceDashboard extends StatelessWidget {
  const MaintenanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final propertyService = Provider.of<PropertyService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('Maintenance Requests', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<MaintenanceRequestModel>>(
        stream: propertyService.getOwnerMaintenanceRequestsStream(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Text('No maintenance requests found.', style: TextStyle(color: AppTheme.subtext(context))),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildMaintenanceCard(context, request, propertyService);
            },
          );
        },
      ),
    );
  }

  Widget _buildMaintenanceCard(BuildContext context, MaintenanceRequestModel request, PropertyService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.softShadow(context)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              _buildStatusChip(request.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.description,
            style: TextStyle(color: AppTheme.subtext(context)),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: AppTheme.subtext(context)),
              const SizedBox(width: 4),
              Text(request.tenantName, style: TextStyle(fontSize: 13, color: AppTheme.subtext(context))),
              const Spacer(),
              Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.subtext(context)),
              const SizedBox(width: 4),
              Text(
                '${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
                style: TextStyle(fontSize: 13, color: AppTheme.subtext(context)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: MaintenanceStatus.values.map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status.name, style: const TextStyle(fontSize: 11)),
                          selected: request.status == status,
                          onSelected: (selected) {
                            if (selected) {
                              service.updateMaintenanceStatus(request.id, status.name);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(MaintenanceStatus status) {
    Color color;
    switch (status) {
      case MaintenanceStatus.pending: color = Colors.orange; break;
      case MaintenanceStatus.inProgress: color = Colors.blue; break;
      case MaintenanceStatus.resolved: color = Colors.green; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
