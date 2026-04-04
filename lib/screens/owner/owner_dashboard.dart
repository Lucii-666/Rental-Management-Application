import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../utils/app_theme.dart';
import '../../models/property_model.dart';
import '../../models/join_request_model.dart';
import '../../models/room_request_model.dart';
import '../../models/maintenance_model.dart';
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

class _OwnerDashboardState extends State<OwnerDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final propertyService = Provider.of<PropertyService>(context, listen: false);
    final dark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: _buildAppBar(authService, propertyService),
      drawer: _buildDrawer(authService),
      body: StreamBuilder<List<PropertyModel>>(
        stream: propertyService.getPropertiesStream(authService.currentUser!.uid),
        builder: (context, snapshot) {
          final properties = snapshot.data ?? [];
          return FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(authService, dark),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(properties, authService, propertyService),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Your Properties', onAdd: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
                        }),
                        const SizedBox(height: 16),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          _buildLoadingCards()
                        else if (properties.isEmpty)
                          _buildEmptyState()
                        else
                          ...properties.asMap().entries.map((e) =>
                              _buildPropertyCard(e.value, e.key)),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Quick Actions'),
                        const SizedBox(height: 16),
                        _buildShortcutCard(
                          'Rent Collection',
                          'Track payments, mark as paid & send reminders',
                          Icons.receipt_long_rounded,
                          AppTheme.primaryGradient,
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RentCollectionScreen())),
                        ),
                        const SizedBox(height: 14),
                        _buildShortcutCard(
                          'Document Verification',
                          'Review & verify tenant identity documents',
                          Icons.verified_user_rounded,
                          AppTheme.cyanGradient,
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const DocumentVerificationScreen())),
                        ),
                        const SizedBox(height: 14),
                        _buildShortcutCard(
                          'Tenant History',
                          'View past tenants, move-out dates & reasons',
                          Icons.history_rounded,
                          const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF9D4EDD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const TenantHistoryScreen())),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AuthService authService, PropertyService propertyService) {
    return AppBar(
      backgroundColor: AppTheme.bg(context),
      elevation: 0,
      leading: Builder(builder: (ctx) => IconButton(
        icon: Icon(Icons.menu_rounded, color: AppTheme.text(context)),
        onPressed: () => Scaffold.of(ctx).openDrawer(),
      )),
      actions: [
        StreamBuilder<List<JoinRequestModel>>(
          stream: propertyService.getOwnerJoinRequestsStream(authService.currentUser!.uid),
          builder: (context, joinSnap) {
            return StreamBuilder<List<RoomRequestModel>>(
              stream: propertyService.getOwnerRoomRequestsStream(authService.currentUser!.uid),
              builder: (context, roomSnap) {
                final total = (joinSnap.data?.length ?? 0) + (roomSnap.data?.length ?? 0);
                return _buildBadgeButton(
                  icon: Icons.inbox_rounded,
                  count: total,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RequestsHubScreen())),
                );
              },
            );
          },
        ),
        StreamBuilder<List<NotificationModel>>(
          stream: Provider.of<NotificationService>(context).getNotificationsStream(
              authService.currentUser?.uid ?? ''),
          builder: (context, snap) {
            final unread = snap.data?.where((n) => !n.isRead).length ?? 0;
            return _buildBadgeButton(
              icon: Icons.notifications_rounded,
              count: unread,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            );
          },
        ),
        Consumer<ThemeProvider>(
          builder: (context, tp, _) => IconButton(
            icon: Icon(
              tp.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: AppTheme.primary(context),
            ),
            onPressed: tp.toggle,
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBadgeButton({required IconData icon, required int count, required VoidCallback onTap}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(icon, color: AppTheme.text(context)),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(AuthService auth, bool dark) {
    final name = auth.userModel?.name?.split(' ').first ?? 'Owner';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [AppTheme.darkBackgroundColor, AppTheme.darkSurfaceColor]
              : [AppTheme.backgroundColor, const Color(0xFFEEF2FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()},',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.subtext(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (bounds) => (dark
                          ? AppTheme.darkPrimaryGradient
                          : AppTheme.primaryGradient)
                      .createShader(bounds),
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: dark ? AppTheme.darkPrimaryGradient : AppTheme.primaryGradient,
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.card(context),
                backgroundImage: auth.userModel?.photoUrl != null
                    ? NetworkImage(auth.userModel!.photoUrl!)
                    : null,
                child: auth.userModel?.photoUrl == null
                    ? Icon(Icons.person_rounded, color: AppTheme.primary(context), size: 28)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<PropertyModel> properties,
      AuthService authService, PropertyService propertyService) {
    return FutureBuilder<Map<String, int>>(
      future: propertyService.getOwnerStats(authService.currentUser!.uid),
      builder: (context, snapshot) {
        final stats = snapshot.data ??
            {'properties': properties.length, 'rooms': 0, 'tenants': 0};
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildStatCard('Properties', stats['properties'].toString(),
                    Icons.location_city_rounded, AppTheme.primaryGradient)),
                const SizedBox(width: 14),
                Expanded(child: _buildStatCard('Rooms', stats['rooms'].toString(),
                    Icons.door_front_door_rounded, AppTheme.cyanGradient)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildStatCard('Tenants', stats['tenants'].toString(),
                    Icons.people_rounded, AppTheme.emeraldGradient)),
                const SizedBox(width: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MaintenanceDashboard())),
                    child: StreamBuilder<List<MaintenanceRequestModel>>(
                      stream: propertyService.getOwnerMaintenanceRequestsStream(
                          authService.currentUser!.uid),
                      builder: (context, snap) {
                        final pending = snap.data
                                ?.where((r) => r.status != MaintenanceStatus.resolved)
                                .length ?? 0;
                        return _buildStatCard('Requests', '$pending',
                            Icons.build_rounded, AppTheme.roseGradient);
                      },
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

  Widget _buildStatCard(String label, String value, IconData icon, LinearGradient gradient) {
    final dark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.text(context),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.subtext(context),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.text(context),
            letterSpacing: 0.2,
          ),
        ),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.isDark(context)
                    ? AppTheme.darkPrimaryGradient
                    : AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('Add New',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPropertyCard(PropertyModel property, int index) {
    return AnimatedSlide(
      offset: Offset(0, 0),
      duration: Duration(milliseconds: 300 + index * 80),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => PropertyDetailsScreen(property: property)));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow(context),
            border: AppTheme.isDark(context)
                ? null
                : Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property.name,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 15,
                            color: AppTheme.text(context))),
                    const SizedBox(height: 2),
                    Text(
                      '${property.city} · ${property.address}',
                      style: GoogleFonts.inter(
                          color: AppTheme.subtext(context), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.chevron_right_rounded,
                    color: AppTheme.primary(context), size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutCard(String title, String subtitle, IconData icon,
      LinearGradient gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          height: 1.4)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCards() {
    return Column(
      children: List.generate(2, (_) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 88,
        decoration: BoxDecoration(
          color: AppTheme.shimmer(context),
          borderRadius: BorderRadius.circular(20),
        ),
      )),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary(context).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_business_rounded,
                  size: 48, color: AppTheme.primary(context).withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            Text('No properties yet',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 16,
                    color: AppTheme.text(context))),
            const SizedBox(height: 4),
            Text('Tap "Add New" to add your first property.',
                style: GoogleFonts.inter(
                    color: AppTheme.subtext(context), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(AuthService auth) {
    final dark = AppTheme.isDark(context);
    return Drawer(
      backgroundColor: AppTheme.surface(context),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
            decoration: BoxDecoration(
              gradient: dark ? AppTheme.darkPrimaryGradient : AppTheme.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    backgroundImage: auth.userModel?.photoUrl != null
                        ? NetworkImage(auth.userModel!.photoUrl!)
                        : null,
                    child: auth.userModel?.photoUrl == null
                        ? const Icon(Icons.person_rounded, color: Colors.white, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  auth.userModel?.name ?? 'Owner',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                if (auth.userModel?.email != null)
                  Text(
                    auth.userModel!.email!,
                    style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildDrawerItem(Icons.person_outline_rounded, 'My Profile', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }),
          _buildDrawerItem(Icons.history_rounded, 'Tenant History', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TenantHistoryScreen()));
          }),
          const Divider(height: 24),
          _buildDrawerItem(Icons.logout_rounded, 'Logout', () => auth.signOut(),
              color: const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? AppTheme.text(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 20),
      ),
      title: Text(label,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w500, color: c, fontSize: 14)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
