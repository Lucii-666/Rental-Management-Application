import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../utils/app_theme.dart';
import '../../models/property_model.dart';
import '../../models/join_request_model.dart';
import '../../models/room_request_model.dart';
import 'add_property_screen.dart';
import 'property_details_screen.dart';
import 'requests_hub_screen.dart';
import 'maintenance_dashboard.dart';
import 'document_verification_screen.dart';
import 'tenant_history_screen.dart';
import 'rent_collection_screen.dart';
import '../shared/profile_screen.dart';
import '../shared/notifications_screen.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../utils/theme_provider.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final propertyService = Provider.of<PropertyService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('Owner Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          StreamBuilder<List<JoinRequestModel>>(
            stream: propertyService.getOwnerJoinRequestsStream(authService.currentUser!.uid),
            builder: (context, joinSnapshot) {
              return StreamBuilder<List<RoomRequestModel>>(
                stream: propertyService.getOwnerRoomRequestsStream(authService.currentUser!.uid),
                builder: (context, roomSnapshot) {
                  final joinCount = joinSnapshot.data?.length ?? 0;
                  final roomCount = roomSnapshot.data?.length ?? 0;
                  final totalCount = joinCount + roomCount;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RequestsHubScreen()),
                          );
                        },
                      ),
                      if (totalCount > 0)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$totalCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
            icon: StreamBuilder<List<NotificationModel>>(
              stream: Provider.of<NotificationService>(context).getNotificationsStream(authService.currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                final unread = snapshot.data?.where((n) => !n.isRead).length ?? 0;
                return Badge(
                  label: unread > 0 ? Text('$unread') : null,
                  isLabelVisible: unread > 0,
                  child: const Icon(Icons.notifications_outlined),
                );
              },
            ),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => IconButton(
              icon: Icon(themeProvider.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              onPressed: themeProvider.toggle,
              tooltip: themeProvider.isDark ? 'Light Mode' : 'Dark Mode',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primary(context)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   CircleAvatar(
                    radius: 35,
                    backgroundColor: AppTheme.card(context),
                    child: Icon(Icons.person, size: 40, color: AppTheme.primary(context)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authService.currentUser?.phoneNumber ?? 'Owner',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('Tenant History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TenantHistoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => authService.signOut(),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<PropertyModel>>(
        stream: propertyService.getPropertiesStream(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final properties = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(properties),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Properties',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary(context),
                          ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add New'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (properties.isEmpty)
                  _buildEmptyState()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      return _buildPropertyCard(properties[index]);
                    },
                  ),
                const SizedBox(height: 32),
                _buildRentCollectionShortcut(),
                const SizedBox(height: 16),
                _buildDocumentVerificationShortcut(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(List<PropertyModel> properties) {
    final propertyService = Provider.of<PropertyService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    return FutureBuilder<Map<String, int>>(
      future: propertyService.getOwnerStats(authService.currentUser!.uid),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'properties': properties.length, 'rooms': 0, 'tenants': 0};
        
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Properties',
                    stats['properties'].toString(),
                    Icons.location_city,
                    AppTheme.primary(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Rooms',
                    stats['rooms'].toString(),
                    Icons.door_front_door,
                    AppTheme.accent(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tenants',
                    stats['tenants'].toString(),
                    Icons.people,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MaintenanceDashboard()),
                      );
                    },
                    child: _buildStatCard(
                      'Requests',
                      '0', // We can add maintenance count later
                      Icons.notifications_active,
                      Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.softShadow(context)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondary(context),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.subtext(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsScreen(property: property),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primary(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.home_work_rounded, color: AppTheme.primary(context)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${property.city} • ${property.address}',
                    style: TextStyle(color: AppTheme.subtext(context), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.subtext(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildRentCollectionShortcut() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RentCollectionScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary(context), const Color(0xFF9C95FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary(context).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: Colors.white, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rent Collection',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Track payments, mark as paid & send reminders',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentVerificationShortcut() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DocumentVerificationScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.teal.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: Colors.white, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Document Verification',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Review & verify tenant identity documents',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 48),
          Icon(Icons.add_business_outlined, size: 80, color: AppTheme.subtext(context).withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No properties added yet',
            style: TextStyle(color: AppTheme.subtext(context), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Add New" to get started.',
            style: TextStyle(color: AppTheme.subtext(context), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
