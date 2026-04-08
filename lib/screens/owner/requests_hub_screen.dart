import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/join_request_model.dart';
import '../../models/room_request_model.dart';
import '../../services/property_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class RequestsHubScreen extends StatefulWidget {
  const RequestsHubScreen({super.key});

  @override
  State<RequestsHubScreen> createState() => _RequestsHubScreenState();
}

class _RequestsHubScreenState extends State<RequestsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertyService = Provider.of<PropertyService>(context);
    final authService = Provider.of<AuthService>(context);
    final ownerId = authService.currentUser!.uid;
    final dark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: _buildAppBar(dark),
      body: TabBarView(
        controller: _tabController,
        children: [
          _JoinRequestsTab(
              propertyService: propertyService, ownerId: ownerId),
          _RoomRequestsTab(
              propertyService: propertyService, ownerId: ownerId),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool dark) {
    return AppBar(
      backgroundColor: AppTheme.bg(context),
      elevation: 0,
      title: Text(
        'Requests Hub',
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, color: AppTheme.text(context)),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          height: 46,
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            padding: const EdgeInsets.all(4),
            indicator: BoxDecoration(
              gradient: dark
                  ? AppTheme.darkPrimaryGradient
                  : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary(context).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.subtext(context),
            labelStyle: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Property Joins'),
              Tab(text: 'Room Requests'),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Property Join Requests Tab
// ─────────────────────────────────────────────────────────────────────────────

class _JoinRequestsTab extends StatelessWidget {
  final PropertyService propertyService;
  final String ownerId;

  const _JoinRequestsTab({
    required this.propertyService,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JoinRequestModel>>(
      stream: propertyService.getOwnerJoinRequestsStream(ownerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data!;

        if (requests.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.home_work_outlined,
            title: 'No Join Requests',
            subtitle: 'When tenants request to join your property, they\'ll appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          physics: const BouncingScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _JoinRequestCard(
              request: requests[index],
              propertyService: propertyService,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Room Requests Tab
// ─────────────────────────────────────────────────────────────────────────────

class _RoomRequestsTab extends StatelessWidget {
  final PropertyService propertyService;
  final String ownerId;

  const _RoomRequestsTab({
    required this.propertyService,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoomRequestModel>>(
      stream: propertyService.getOwnerRoomRequestsStream(ownerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data!;

        if (requests.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.meeting_room_outlined,
            title: 'No Room Requests',
            subtitle: 'When tenants request specific rooms, they\'ll appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          physics: const BouncingScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _RoomRequestCard(
              request: requests[index],
              propertyService: propertyService,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Join Request Card
// ─────────────────────────────────────────────────────────────────────────────

class _JoinRequestCard extends StatelessWidget {
  final JoinRequestModel request;
  final PropertyService propertyService;

  const _JoinRequestCard({
    required this.request,
    required this.propertyService,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(request.tenantId)
          .snapshots(),
      builder: (context, snapshot) {
        UserModel? user;
        if (snapshot.hasData && snapshot.data!.exists) {
          user = UserModel.fromMap(
              snapshot.data!.data() as Map<String, dynamic>);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow(context),
            border: dark
                ? null
                : Border.all(
                    color: const Color(0xFFE2E8F0), width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: dark
                            ? AppTheme.darkPrimaryGradient
                            : AppTheme.primaryGradient,
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.bg(context),
                        backgroundImage: user?.photoUrl != null
                            ? NetworkImage(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? Icon(Icons.person_rounded,
                                color: AppTheme.primary(context), size: 26)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.tenantName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppTheme.text(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.home_work_rounded,
                                  size: 12,
                                  color: AppTheme.subtext(context)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Wants to join ${request.propertyName}',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.subtext(context)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Pending',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),

                // Bio
                if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.format_quote_rounded,
                            size: 16,
                            color: AppTheme.primary(context)
                                .withValues(alpha: 0.6)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            user.bio!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.subtext(context),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Phone
                if (request.tenantPhone.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(context,
                      icon: Icons.phone_rounded,
                      label: 'Phone',
                      value: request.tenantPhone),
                ],

                const SizedBox(height: 16),
                _buildTimestamp(context, request.createdAt),
                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildRejectButton(context, () {
                        propertyService.handleJoinRequest(request.id, false);
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAcceptButton(context, () {
                        propertyService.handleJoinRequest(request.id, true);
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Room Request Card
// ─────────────────────────────────────────────────────────────────────────────

class _RoomRequestCard extends StatefulWidget {
  final RoomRequestModel request;
  final PropertyService propertyService;

  const _RoomRequestCard({
    required this.request,
    required this.propertyService,
  });

  @override
  State<_RoomRequestCard> createState() => _RoomRequestCardState();
}

class _RoomRequestCardState extends State<_RoomRequestCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final req = widget.request;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow(context),
        border: dark
            ? null
            : Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: dark
                        ? AppTheme.darkPrimaryGradient
                        : AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.meeting_room_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.tenantName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.text(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.door_back_door_rounded,
                              size: 12, color: AppTheme.subtext(context)),
                          const SizedBox(width: 4),
                          Text(
                            'Requested Room ${req.roomNumber}',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.subtext(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.primary(context), size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Expanded tenant details
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedDetails(context, req, dark),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),

          // Timestamp + action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimestamp(context, req.timestamp),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildRejectButton(context, () {
                        widget.propertyService
                            .handleRoomRequest(req.id, false);
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAcceptButton(context, () {
                        widget.propertyService
                            .handleRoomRequest(req.id, true);
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(
      BuildContext context, RoomRequestModel req, bool dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            color: AppTheme.dividerColor(context),
          ),
          const SizedBox(height: 14),
          Text(
            'Tenant Details',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.subtext(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.dividerColor(context), width: 1),
            ),
            child: Column(
              children: [
                if (req.tenantPhone.isNotEmpty)
                  _buildDetailRow(context,
                      icon: Icons.phone_rounded,
                      label: 'Phone',
                      value: req.tenantPhone),
                if (req.tenantEmail.isNotEmpty) ...[
                  if (req.tenantPhone.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                          height: 1,
                          color: AppTheme.dividerColor(context)),
                    ),
                  _buildDetailRow(context,
                      icon: Icons.email_rounded,
                      label: 'Email',
                      value: req.tenantEmail),
                ],
                if (req.tenantAge > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                        height: 1,
                        color: AppTheme.dividerColor(context)),
                  ),
                  _buildDetailRow(context,
                      icon: Icons.cake_rounded,
                      label: 'Age',
                      value: '${req.tenantAge} years'),
                ],
                if (req.maritalStatus.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                        height: 1,
                        color: AppTheme.dividerColor(context)),
                  ),
                  _buildDetailRow(context,
                      icon: Icons.favorite_border_rounded,
                      label: 'Marital Status',
                      value: req.maritalStatus),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context,
      {required IconData icon,
      required String label,
      required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primary(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 14, color: AppTheme.primary(context)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppTheme.subtext(context),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.text(context),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildEmptyState(BuildContext context,
    {required IconData icon,
    required String title,
    required String subtitle}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow(context),
            ),
            child: Icon(icon, size: 48, color: AppTheme.subtext(context)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.text(context)),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.subtext(context),
                height: 1.5),
          ),
        ],
      ),
    ),
  );
}

Widget _buildInfoRow(BuildContext context,
    {required IconData icon,
    required String label,
    required String value}) {
  return Row(
    children: [
      Icon(icon, size: 14, color: AppTheme.subtext(context)),
      const SizedBox(width: 6),
      Text(
        '$label: ',
        style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.subtext(context),
            fontWeight: FontWeight.w500),
      ),
      Text(
        value,
        style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.text(context),
            fontWeight: FontWeight.w500),
      ),
    ],
  );
}

Widget _buildTimestamp(BuildContext context, DateTime dt) {
  return Row(
    children: [
      Icon(Icons.access_time_rounded,
          size: 12, color: AppTheme.subtext(context)),
      const SizedBox(width: 5),
      Text(
        DateFormat('dd MMM yyyy • hh:mm a').format(dt),
        style: GoogleFonts.inter(
            fontSize: 11, color: AppTheme.subtext(context)),
      ),
    ],
  );
}

Widget _buildAcceptButton(BuildContext context, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.emeraldGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              'Accept',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildRejectButton(BuildContext context, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.6), width: 1.5),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close_rounded,
                color: Color(0xFFEF4444), size: 16),
            const SizedBox(width: 6),
            Text(
              'Reject',
              style: GoogleFonts.poppins(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
