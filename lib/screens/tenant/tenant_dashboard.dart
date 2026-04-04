import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({super.key});

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard>
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
    final authService = Provider.of<AuthService>(context);
    final propertyService = Provider.of<PropertyService>(context);
    final user = authService.userModel;
    final bool hasProperty = user?.propertyId != null && user!.propertyId!.isNotEmpty;
    final dark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: _buildAppBar(authService),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(authService, dark),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasProperty) ...[
                      _buildActionRequired(),
                      const SizedBox(height: 20),
                      _buildOptionCard(
                        'Join a Property',
                        'Enter a join code to connect to your home',
                        Icons.home_work_rounded,
                        AppTheme.primaryGradient,
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const JoinPropertyScreen())),
                      ),
                    ] else ...[
                      _buildRoomRequestStatus(propertyService, user!.uid),
                      _buildRentSummary(user),
                      const SizedBox(height: 16),
                      _buildOptionCard(
                        'My Property',
                        'View rooms, occupancy info and details',
                        Icons.apartment_rounded,
                        AppTheme.cyanGradient,
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => PropertyExplorerScreen(
                                propertyId: user.propertyId!))),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildOptionCard(
                      'Verify Identity',
                      'Upload your ID for security clearance',
                      Icons.verified_user_rounded,
                      AppTheme.amberGradient,
                      () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const IdentityUploadScreen())),
                    ),
                    const SizedBox(height: 16),
                    _buildOptionCard(
                      'Maintenance',
                      'View your requests or report a new issue',
                      Icons.build_circle_rounded,
                      AppTheme.roseGradient,
                      () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MyMaintenanceScreen())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AuthService authService) {
    return AppBar(
      backgroundColor: AppTheme.bg(context),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text('Home',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, color: AppTheme.text(context))),
      actions: [
        IconButton(
          icon: Icon(Icons.person_outline_rounded, color: AppTheme.text(context)),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())),
        ),
        StreamBuilder<List<NotificationModel>>(
          stream: Provider.of<NotificationService>(context).getNotificationsStream(
              authService.currentUser?.uid ?? ''),
          builder: (context, snap) {
            final unread = snap.data?.where((n) => !n.isRead).length ?? 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_rounded, color: AppTheme.text(context)),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
                if (unread > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Color(0xFFEF4444), shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$unread',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ),
                  ),
              ],
            );
          },
        ),
        Consumer<ThemeProvider>(
          builder: (ctx, tp, _) => IconButton(
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

  Widget _buildHeader(AuthService auth, bool dark) {
    final name = auth.userModel?.name?.split(' ').first ?? 'Tenant';
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
                Text('${_greeting()},',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.subtext(context),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (bounds) => (dark
                          ? AppTheme.darkPrimaryGradient
                          : AppTheme.primaryGradient)
                      .createShader(bounds),
                  child: Text(name,
                      style: GoogleFonts.poppins(
                          fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(height: 4),
                Text('Manage your stay & communications here.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.subtext(context))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
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
                    ? Icon(Icons.person_rounded,
                        color: AppTheme.primary(context), size: 28)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRequired() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary(context).withValues(alpha: 0.12),
            AppTheme.accent(context).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.primary(context).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppTheme.isDark(context)
                  ? AppTheme.darkPrimaryGradient
                  : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Get Started',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.text(context))),
                const SizedBox(height: 2),
                Text(
                    "You haven't joined a property yet. Join one to see your room details.",
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.subtext(context), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentSummary(UserModel user) {
    final rentService = Provider.of<RentService>(context, listen: false);
    return StreamBuilder<RentPaymentModel?>(
      stream: rentService.getCurrentRentForTenant(user.uid),
      builder: (context, snap) {
        final rent = snap.data;

        Color statusColor;
        String statusLabel;
        LinearGradient statusGradient;

        if (rent == null) {
          statusColor = AppTheme.subtext(context);
          statusLabel = 'No Record';
          statusGradient = LinearGradient(
              colors: [statusColor.withValues(alpha: 0.6), statusColor]);
        } else {
          switch (rent.status) {
            case RentStatus.paid:
              statusColor = const Color(0xFF10B981);
              statusLabel = 'Paid';
              statusGradient = AppTheme.emeraldGradient;
            case RentStatus.partiallyPaid:
              statusColor = const Color(0xFF6366F1);
              statusLabel = 'Partial';
              statusGradient = AppTheme.primaryGradient;
            case RentStatus.overdue:
              statusColor = const Color(0xFFEF4444);
              statusLabel = 'Overdue';
              statusGradient = AppTheme.roseGradient;
            case RentStatus.pending:
              statusColor = const Color(0xFFF59E0B);
              statusLabel = 'Due';
              statusGradient = AppTheme.amberGradient;
          }
        }

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyRentScreen()));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow(context),
              border: AppTheme.isDark(context)
                  ? null
                  : Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rent Summary',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.text(context))),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: statusGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(statusLabel,
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: AppTheme.subtext(context)),
                      ],
                    ),
                  ],
                ),
                if (rent != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: AppTheme.dividerColor(context),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Amount Due',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.subtext(context),
                                  letterSpacing: 0.3)),
                          const SizedBox(height: 4),
                          ShaderMask(
                            shaderCallback: (b) => statusGradient.createShader(b),
                            child: Text(
                              '₹${rent.amount.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            (rent.status == RentStatus.paid ||
                                    rent.status == RentStatus.partiallyPaid)
                                ? 'Paid On'
                                : 'Due Date',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.subtext(context),
                                letterSpacing: 0.3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (rent.status == RentStatus.paid ||
                                        rent.status == RentStatus.partiallyPaid) &&
                                    rent.paidDate != null
                                ? DateFormat('dd MMM yyyy').format(rent.paidDate!)
                                : DateFormat('dd MMM yyyy').format(rent.dueDate),
                            style: GoogleFonts.inter(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ],
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

  Widget _buildOptionCard(String title, String subtitle, IconData icon,
      LinearGradient gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.text(context))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: AppTheme.subtext(context), fontSize: 12)),
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
    );
  }

  Widget _buildRoomRequestStatus(PropertyService service, String tenantId) {
    return StreamBuilder<List<RoomRequestModel>>(
      stream: service.getTenantRoomRequestsStream(tenantId),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        final request = snap.data!.first;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF59E0B).withValues(alpha: 0.12),
                const Color(0xFFFBBF24).withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.amberGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pending_actions_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Room Request Pending',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppTheme.text(context))),
                    Text('You requested Room ${request.roomNumber}. Awaiting approval.',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppTheme.subtext(context))),
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
