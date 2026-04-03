import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import 'join_property_screen.dart';
import 'identity_upload_screen.dart';
import 'property_explorer_screen.dart';
import 'my_maintenance_screen.dart';
import '../../models/room_request_model.dart';
import '../../services/property_service.dart';
import '../shared/profile_screen.dart';
import '../shared/notifications_screen.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../services/rent_service.dart';
import '../../models/rent_model.dart';
import '../../utils/theme_provider.dart';
import 'my_rent_screen.dart';
import 'package:intl/intl.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({super.key});

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final propertyService = Provider.of<PropertyService>(context);
    final user = authService.userModel;
    final bool hasProperty = user?.propertyId != null && user!.propertyId!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('Tenant Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(authService),
            const SizedBox(height: 32),
            if (!hasProperty) ...[
              _buildActionRequired(context),
              const SizedBox(height: 24),
              _buildOptionCard(
                context,
                'Join a Property',
                'Enter a code to join your new home.',
                Icons.home_work_outlined,
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const JoinPropertyScreen()),
                  );
                },
              ),
            ] else ...[
              _buildRoomRequestStatus(propertyService, user.uid),
              const SizedBox(height: 16),
              _buildOptionCard(
                context,
                'My Property',
                'View rooms and occupancy info.',
                Icons.home_work_outlined,
                Colors.green,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyExplorerScreen(propertyId: user.propertyId!),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildRentSummary(user),
            ],
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              'Verify Identity',
              'Upload your ID for security clearance.',
              Icons.verified_user_outlined,
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IdentityUploadScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              'Maintenance',
              'View your requests or report a new issue.',
              Icons.build_circle_outlined,
              Colors.red,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyMaintenanceScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentSummary(UserModel user) {
    final rentService = Provider.of<RentService>(context, listen: false);

    return StreamBuilder<RentPaymentModel?>(
      stream: rentService.getCurrentRentForTenant(user.uid),
      builder: (context, snapshot) {
        final rent = snapshot.data;

        Color statusColor;
        String statusLabel;
        if (rent == null) {
          statusColor = Colors.grey;
          statusLabel = 'No Record';
        } else {
          switch (rent.status) {
            case RentStatus.paid:
              statusColor = Colors.green;
              statusLabel = 'Paid';
            case RentStatus.partiallyPaid:
              statusColor = Colors.blue;
              statusLabel = 'Partial';
            case RentStatus.overdue:
              statusColor = Colors.red;
              statusLabel = 'Overdue';
            case RentStatus.pending:
              statusColor = Colors.orange;
              statusLabel = 'Pending';
          }
        }

        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyRentScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              boxShadow: [AppTheme.softShadow(context)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rent Summary',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('This Month'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                if (rent != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount'),
                      Text('₹${rent.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (rent.status == RentStatus.paid || rent.status == RentStatus.partiallyPaid) ? 'Paid On' : 'Due Date',
                        style: TextStyle(color: AppTheme.subtext(context)),
                      ),
                      Text(
                        (rent.status == RentStatus.paid || rent.status == RentStatus.partiallyPaid) && rent.paidDate != null
                            ? DateFormat('dd MMM yyyy').format(rent.paidDate!)
                            : DateFormat('dd MMM yyyy').format(rent.dueDate),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(AuthService auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${auth.userModel?.name ?? "Tenant"}!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.secondary(context)),
        ),
        Text(
          'Manage your stay and communications here.',
          style: TextStyle(color: AppTheme.subtext(context)),
        ),
      ],
    );
  }

  Widget _buildActionRequired(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary(context).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primary(context), size: 30),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('You haven\'t joined a property yet. Join one to see your room details.', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppTheme.softShadow(context)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: AppTheme.subtext(context), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomRequestStatus(PropertyService service, String tenantId) {
    return StreamBuilder<List<RoomRequestModel>>(
      stream: service.getTenantRoomRequestsStream(tenantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        final request = snapshot.data!.first;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accent(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accent(context).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.pending_actions, color: Colors.orange),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Room Request Pending', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('You requested Room ${request.roomNumber}. Waiting for approval.', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
