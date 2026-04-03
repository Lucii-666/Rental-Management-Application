import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property_model.dart';
import '../../models/room_model.dart';
import '../../services/property_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class PropertyExplorerScreen extends StatefulWidget {
  final String propertyId;
  const PropertyExplorerScreen({super.key, required this.propertyId});

  @override
  State<PropertyExplorerScreen> createState() => _PropertyExplorerScreenState();
}

class _PropertyExplorerScreenState extends State<PropertyExplorerScreen> {
  @override
  Widget build(BuildContext context) {
    final propertyService = Provider.of<PropertyService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Property Details')),
      body: StreamBuilder<PropertyModel>(
        stream: propertyService.getPropertyStream(widget.propertyId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final property = snapshot.data!;

          return Column(
            children: [
              _buildHeader(property),
              const Divider(),
              Expanded(
                child: StreamBuilder<List<RoomModel>>(
                  stream: propertyService.getRoomsStream(widget.propertyId),
                  builder: (context, roomSnapshot) {
                    if (!roomSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final rooms = roomSnapshot.data!;

                    if (rooms.isEmpty) {
                      return const Center(child: Text('No rooms available yet.'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        return _buildRoomTile(rooms[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(PropertyModel property) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(property.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppTheme.subtext(context)),
              const SizedBox(width: 4),
              Text(property.address, style: TextStyle(color: AppTheme.subtext(context))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTile(RoomModel room) {
    bool isFull = room.currentOccupancy >= room.maxOccupancy;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text('Room ${room.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Rent: ₹${room.rentAmount} / month'),
            Text('Occupancy: ${room.currentOccupancy} / ${room.maxOccupancy}'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: isFull ? null : () {
            // Room Request Logic
            _showRoomRequestDialog(room);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isFull ? Colors.grey : AppTheme.primary(context),
          ),
          child: Text(isFull ? 'Full' : 'Request'),
        ),
      ),
    );
  }

  void _showRoomRequestDialog(RoomModel room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Room'),
        content: Text('Do you want to send a request to join Room ${room.roomNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final propertyService = Provider.of<PropertyService>(context, listen: false);
              final user = authService.userModel!;
              
              // Capture context-dependent objects before async gaps
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              final property = await propertyService.getPropertyStream(widget.propertyId).first;

              final error = await propertyService.sendRoomRequest(
                tenantId: user.uid,
                tenantName: user.name,
                propertyId: widget.propertyId,
                roomId: room.id,
                roomNumber: room.roomNumber,
                ownerId: property.ownerId,
              );

              if (!mounted) return;
              navigator.pop();

              if (error == null) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Room request sent to owner!')),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error: $error')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
