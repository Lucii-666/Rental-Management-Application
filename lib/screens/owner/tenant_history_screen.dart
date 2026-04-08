import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../utils/app_theme.dart';
import 'tenant_profile_details_screen.dart';

class TenantHistoryScreen extends StatefulWidget {
  const TenantHistoryScreen({super.key});

  @override
  State<TenantHistoryScreen> createState() => _TenantHistoryScreenState();
}

class _TenantHistoryScreenState extends State<TenantHistoryScreen>
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final propertyService = Provider.of<PropertyService>(context, listen: false);
    final uid = authService.currentUser!.uid;
    final dark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        title: Text('Tenants',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: AppTheme.text(context))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: dark
                    ? AppTheme.darkPrimaryGradient
                    : AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(9),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.subtext(context),
              labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Current'),
                Tab(text: 'Former'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CurrentTenantsTab(uid: uid, propertyService: propertyService),
          _FormerTenantsTab(uid: uid, propertyService: propertyService),
        ],
      ),
    );
  }
}

// ─── Current Tenants Tab ──────────────────────────────────────────────────────

class _CurrentTenantsTab extends StatelessWidget {
  final String uid;
  final PropertyService propertyService;
  const _CurrentTenantsTab({required this.uid, required this.propertyService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: propertyService.getOwnerCurrentTenantsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tenants = snapshot.data ?? [];

        if (tenants.isEmpty) {
          return _buildEmpty(context, 'No current tenants.',
              Icons.people_outline_rounded);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          itemCount: tenants.length,
          itemBuilder: (context, index) =>
              _buildCurrentTenantCard(context, tenants[index]),
        );
      },
    );
  }

  Widget _buildCurrentTenantCard(
      BuildContext context, Map<String, dynamic> tenant) {
    final joinedAt = _formatDate(tenant['joinedAt']);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TenantProfileDetailsScreen(tenantId: tenant['id']),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.primary(context).withValues(alpha: 0.2)),
          boxShadow: [AppTheme.softShadow(context)],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (tenant['name'] ?? '?')[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tenant['name'] ?? 'Unknown',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.text(context))),
                  if ((tenant['phone'] ?? '').toString().isNotEmpty)
                    Text(tenant['phone'],
                        style: GoogleFonts.inter(
                            color: AppTheme.subtext(context), fontSize: 13)),
                  Text('Since $joinedAt',
                      style: GoogleFonts.inter(
                          color: AppTheme.subtext(context), fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('ACTIVE',
                      style: GoogleFonts.inter(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                          fontSize: 10)),
                ),
                const SizedBox(height: 4),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppTheme.subtext(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Former Tenants Tab ───────────────────────────────────────────────────────

class _FormerTenantsTab extends StatelessWidget {
  final String uid;
  final PropertyService propertyService;
  const _FormerTenantsTab({required this.uid, required this.propertyService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: propertyService.getOwnerTenantHistoryStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = snapshot.data ?? [];

        if (history.isEmpty) {
          return _buildEmpty(context, 'No former tenants.',
              Icons.history_rounded);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          itemCount: history.length,
          itemBuilder: (context, index) =>
              _buildFormerCard(context, history[index]),
        );
      },
    );
  }

  Widget _buildFormerCard(BuildContext context, Map<String, dynamic> record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor(context)),
        boxShadow: [AppTheme.softShadow(context)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.subtext(context).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (record['name'] ?? '?')[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                        color: AppTheme.subtext(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record['name'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.text(context))),
                    if ((record['phone'] ?? '').toString().isNotEmpty)
                      Text(record['phone'],
                          style: GoogleFonts.inter(
                              color: AppTheme.subtext(context), fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('FORMER',
                    style: GoogleFonts.inter(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                        fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Property: ${record['propertyName'] ?? '-'}',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.text(context))),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dateCol(context, 'Joined', _formatDate(record['joinedAt']),
                  Colors.green),
              _dateCol(context, 'Left', _formatDate(record['leftAt']),
                  Colors.red),
            ],
          ),
          if ((record['removalReason'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: AppTheme.subtext(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(record['removalReason'],
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.subtext(context))),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateCol(
      BuildContext context, String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppTheme.subtext(context))),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor)),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _buildEmpty(BuildContext context, String message, IconData icon) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppTheme.subtext(context).withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(message,
              style: GoogleFonts.inter(color: AppTheme.subtext(context))),
        ],
      ),
    ),
  );
}

String _formatDate(dynamic dateStr) {
  if (dateStr == null) return '-';
  try {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  } catch (_) {
    return '-';
  }
}
