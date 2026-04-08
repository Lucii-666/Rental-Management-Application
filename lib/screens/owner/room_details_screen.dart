import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart';
import '../../services/property_service.dart';
import '../../utils/app_theme.dart';
import 'tenant_profile_details_screen.dart';

class RoomDetailsScreen extends StatelessWidget {
  final String propertyId;
  final RoomModel room;

  const RoomDetailsScreen({super.key, required this.propertyId, required this.room});

  @override
  Widget build(BuildContext context) {
    final propertyService = Provider.of<PropertyService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text('Room ${room.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Fix occupancy count',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () async {
              await Provider.of<PropertyService>(context, listen: false)
                  .syncRoomOccupancy(propertyId, room.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Occupancy count synced.')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoomSummary(context),
            const SizedBox(height: 32),
            Text(
              'Current Tenants',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.secondary(context)),
            ),
            const SizedBox(height: 16),
            _buildTenantsList(propertyService),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppTheme.softShadow(context)],
      ),
      child: Column(
        children: [
          _buildSummaryRow(context, Icons.payments_outlined, 'Monthly Rent', '₹${room.rentAmount}'),
          const Divider(height: 32),
          _buildSummaryRow(context, Icons.people_outline, 'Occupancy', '${room.currentOccupancy} / ${room.maxOccupancy}'),
          const Divider(height: 32),
          _buildSummaryRow(context, Icons.info_outline, 'Status', room.status),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary(context)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: AppTheme.subtext(context))),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildTenantsList(PropertyService service) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getRoomTenantsStream(propertyId, room.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('No tenants assigned to this room.'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final tenant = snapshot.data![index];
            return _buildTenantCard(context, tenant);
          },
        );
      },
    );
  }

  Widget _buildTenantCard(BuildContext context, Map<String, dynamic> tenant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primary(context).withValues(alpha: 0.1),
            child: Icon(Icons.person, color: AppTheme.primary(context)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tenant['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(tenant['phone'] ?? '', style: TextStyle(color: AppTheme.subtext(context), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
            onPressed: () => _showRemoveTenantDialog(context, tenant),
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: AppTheme.primary(context)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TenantProfileDetailsScreen(tenantId: tenant['id']),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRemoveTenantDialog(BuildContext context, Map<String, dynamic> tenant) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${tenant['name']}?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason for removal (Optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<PropertyService>(context, listen: false).removeTenantFromRoom(
                propertyId,
                room.id,
                tenant['id'],
                reasonController.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Remove'),
          ),
        ],
      ),
    );
  }
}
