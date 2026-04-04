import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/property_model.dart';
import '../../models/rent_model.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../services/rent_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/receipt_generator.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class RentCollectionScreen extends StatefulWidget {
  const RentCollectionScreen({super.key});

  @override
  State<RentCollectionScreen> createState() => _RentCollectionScreenState();
}

class _RentCollectionScreenState extends State<RentCollectionScreen>
    with SingleTickerProviderStateMixin {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // ── Status helpers ──────────────────────────────────────────────────────────

  Color _statusColor(RentStatus status) {
    switch (status) {
      case RentStatus.paid:
        return const Color(0xFF10B981); // emerald
      case RentStatus.partiallyPaid:
        return const Color(0xFF6366F1); // indigo
      case RentStatus.overdue:
        return const Color(0xFFE11D48); // rose
      case RentStatus.pending:
        return const Color(0xFFF59E0B); // amber
    }
  }

  LinearGradient _statusGradient(RentStatus status) {
    switch (status) {
      case RentStatus.paid:
        return AppTheme.emeraldGradient;
      case RentStatus.partiallyPaid:
        return AppTheme.primaryGradient;
      case RentStatus.overdue:
        return AppTheme.roseGradient;
      case RentStatus.pending:
        return AppTheme.amberGradient;
    }
  }

  String _statusLabel(RentStatus status) {
    switch (status) {
      case RentStatus.paid:
        return 'Paid';
      case RentStatus.partiallyPaid:
        return 'Partial';
      case RentStatus.overdue:
        return 'Overdue';
      case RentStatus.pending:
        return 'Pending';
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final rentService = Provider.of<RentService>(context, listen: false);
    final ownerId = authService.currentUser!.uid;
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          'Rent Collection',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.text(context),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildMonthSelector(isDark),
          Expanded(
            child: StreamBuilder<List<RentPaymentModel>>(
              stream: rentService.getRentStreamForOwner(
                ownerId: ownerId,
                month: _selectedMonth,
                year: _selectedYear,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerList(isDark);
                }

                final records = snapshot.data ?? [];

                return Column(
                  children: [
                    _buildSummaryBar(records, isDark),
                    Expanded(
                      child: records.isEmpty
                          ? _buildEmptyState(ownerId, rentService)
                          : _buildRentList(records, rentService),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildGenerateButton(ownerId),
    );
  }

  // ── Month / year selector ───────────────────────────────────────────────────

  Widget _buildMonthSelector(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.gradient(context),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildStyledDropdown<int>(
              value: _selectedMonth,
              items: List.generate(12, (i) => i + 1),
              labelBuilder: (m) => _months[m - 1],
              onChanged: (v) => setState(() => _selectedMonth = v!),
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: AppTheme.dividerColor(context),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          _buildStyledDropdown<int>(
            value: _selectedYear,
            items:
                List.generate(3, (i) => DateTime.now().year - 1 + i),
            labelBuilder: (y) => '$y',
            onChanged: (v) => setState(() => _selectedYear = v!),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStyledDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isDense: true,
        dropdownColor: AppTheme.card(context),
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.text(context),
        ),
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: AppTheme.subtext(context), size: 20),
        items: items
            .map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelBuilder(item)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // ── Premium summary bar ─────────────────────────────────────────────────────

  Widget _buildSummaryBar(List<RentPaymentModel> records, bool isDark) {
    final total = records.fold<double>(0, (sum, r) => sum + r.amount);
    final collected = records.fold<double>(0, (sum, r) {
      if (r.status == RentStatus.paid) return sum + r.amount;
      if (r.status == RentStatus.partiallyPaid) return sum + r.paidAmount;
      return sum;
    });
    final pending = total - collected;
    final ratio = total > 0 ? (collected / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.darkPrimaryGradient : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          AppTheme.glowShadow(context, color: AppTheme.primary(context)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryStat(
                label: 'Collected',
                value: '₹${collected.toStringAsFixed(0)}',
                valueColor: const Color(0xFF6EE7B7),
                icon: Icons.check_circle_rounded,
                iconGradient: AppTheme.emeraldGradient,
              ),
              Container(
                  width: 1, height: 50, color: Colors.white.withValues(alpha: 0.2)),
              _buildSummaryStat(
                label: 'Pending',
                value: '₹${pending.toStringAsFixed(0)}',
                valueColor: const Color(0xFFFCD34D),
                icon: Icons.hourglass_top_rounded,
                iconGradient: AppTheme.amberGradient,
              ),
              Container(
                  width: 1, height: 50, color: Colors.white.withValues(alpha: 0.2)),
              _buildSummaryStat(
                label: 'Total',
                value: '₹${total.toStringAsFixed(0)}',
                valueColor: Colors.white,
                icon: Icons.account_balance_wallet_rounded,
                iconGradient: AppTheme.cyanGradient,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Collection Progress',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${(ratio * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      height: 6,
                      width: (MediaQuery.of(context).size.width - 72) * ratio,
                      decoration: BoxDecoration(
                        gradient: AppTheme.emeraldGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
    required LinearGradient iconGradient,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: iconGradient,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Rent list ───────────────────────────────────────────────────────────────

  Widget _buildRentList(List<RentPaymentModel> records, RentService rentService) {
    final sorted = [...records]
      ..sort((a, b) {
        final order = {
          RentStatus.overdue: 0,
          RentStatus.pending: 1,
          RentStatus.partiallyPaid: 2,
          RentStatus.paid: 3,
        };
        return (order[a.status] ?? 1).compareTo(order[b.status] ?? 1);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: sorted.length,
      itemBuilder: (context, index) =>
          _buildRentCard(sorted[index], rentService),
    );
  }

  // ── Rent card ───────────────────────────────────────────────────────────────

  Widget _buildRentCard(RentPaymentModel rent, RentService rentService) {
    final statusColor = _statusColor(rent.status);
    final statusGrad = _statusGradient(rent.status);
    final statusLabel = _statusLabel(rent.status);
    final isDark = AppTheme.isDark(context);

    final isActionable = rent.status == RentStatus.pending ||
        rent.status == RentStatus.overdue;
    final isPartial = rent.status == RentStatus.partiallyPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow(context),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: avatar + name/room + status badge
            Row(
              children: [
                // Gradient avatar with initial
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.gradient(context),
                    boxShadow: [
                      AppTheme.glowShadow(context,
                          color: AppTheme.primary(context)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      rent.tenantName.isNotEmpty
                          ? rent.tenantName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rent.tenantName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.text(context),
                        ),
                      ),
                      Text(
                        'Room ${rent.roomNumber}',
                        style: GoogleFonts.inter(
                          color: AppTheme.subtext(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status gradient pill badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: statusGrad,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(
                color: AppTheme.dividerColor(context),
                height: 1,
                thickness: 1),
            const SizedBox(height: 14),

            // Amount + date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${rent.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text(context),
                        height: 1,
                      ),
                    ),
                    if (rent.carryForward > 0) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '₹${rent.baseAmount.toStringAsFixed(0)} base + ₹${rent.carryForward.toStringAsFixed(0)} due',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFF59E0B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        rent.status == RentStatus.paid
                            ? Icons.check_circle_outline_rounded
                            : Icons.schedule_rounded,
                        color: statusColor,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        rent.status == RentStatus.paid
                            ? 'Paid ${DateFormat('dd MMM').format(rent.paidDate!)}'
                            : 'Due ${DateFormat('dd MMM').format(rent.dueDate)}',
                        style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Partial info banner
            if (isPartial) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF818CF8), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Paid ₹${rent.paidAmount.toStringAsFixed(0)} — ₹${rent.balance.toStringAsFixed(0)} carries to next month',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF818CF8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Receipt button for paid / partially paid
            if (rent.status == RentStatus.paid ||
                rent.status == RentStatus.partiallyPaid) ...[
              const SizedBox(height: 14),
              _buildReceiptButton(rent),
            ],

            // Action buttons for actionable statuses
            if (isActionable) ...[
              const SizedBox(height: 14),
              _buildActionButtons(rent, rentService),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptButton(RentPaymentModel rent) {
    return GestureDetector(
      onTap: () => ReceiptGenerator.shareReceipt(rent),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primary(context).withValues(alpha: 0.5),
            width: 1.5,
          ),
          gradient: LinearGradient(
            colors: [
              AppTheme.primary(context).withValues(alpha: 0.06),
              AppTheme.primary(context).withValues(alpha: 0.02),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_outlined,
                color: AppTheme.primary(context), size: 17),
            const SizedBox(width: 8),
            Text(
              'Download Receipt',
              style: GoogleFonts.inter(
                color: AppTheme.primary(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(RentPaymentModel rent, RentService rentService) {
    return Row(
      children: [
        // Remind
        Expanded(
          child: _buildActionChip(
            label: 'Remind',
            icon: Icons.notifications_outlined,
            color: const Color(0xFFF59E0B),
            gradient: AppTheme.amberGradient,
            outlined: true,
            onTap: () => _sendReminder(rent, rentService),
          ),
        ),
        const SizedBox(width: 8),
        // Partial
        Expanded(
          child: _buildActionChip(
            label: 'Partial',
            icon: Icons.payments_outlined,
            color: const Color(0xFF6366F1),
            gradient: AppTheme.primaryGradient,
            outlined: true,
            onTap: () => _recordPartialPayment(rent, rentService),
          ),
        ),
        const SizedBox(width: 8),
        // Paid
        Expanded(
          child: _buildActionChip(
            label: 'Mark Paid',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            gradient: AppTheme.emeraldGradient,
            outlined: false,
            onTap: () => _markAsPaid(rent, rentService),
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required LinearGradient gradient,
    required bool outlined,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: outlined ? null : gradient,
          border: outlined
              ? Border.all(color: color.withValues(alpha: 0.6), width: 1.5)
              : null,
          color: outlined
              ? color.withValues(alpha: AppTheme.isDark(context) ? 0.1 : 0.06)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: outlined ? color : Colors.white, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                color: outlined ? color : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shimmer skeleton loading ─────────────────────────────────────────────────

  Widget _buildShimmerList(bool isDark) {
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade200;
    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState(String ownerId, RentService rentService) {
    final isDark = AppTheme.isDark(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary(context).withValues(alpha: 0.12),
                    AppTheme.primary(context).withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AppTheme.primary(context).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No rent records yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.text(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Generate Rent" below to create records for all tenants in your properties for this period.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.subtext(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB: generate rent ───────────────────────────────────────────────────────

  Widget _buildGenerateButton(String ownerId) {
    final propertyService =
        Provider.of<PropertyService>(context, listen: false);
    final rentService = Provider.of<RentService>(context, listen: false);

    return StreamBuilder<List<PropertyModel>>(
      stream: propertyService.getPropertiesStream(ownerId),
      builder: (context, snapshot) {
        final properties = snapshot.data ?? [];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AppTheme.gradient(context),
            boxShadow: [
              AppTheme.glowShadow(context, color: AppTheme.primary(context)),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _generateRent(ownerId, properties, rentService),
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.receipt_long_rounded,
                color: Colors.white, size: 22),
            label: Text(
              'Generate Rent',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Business logic (unchanged) ───────────────────────────────────────────────

  Future<void> _generateRent(
      String ownerId,
      List<PropertyModel> properties,
      RentService rentService) async {
    if (properties.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No properties found.')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    for (final property in properties) {
      await rentService.generateRentForProperty(
        propertyId: property.id,
        ownerId: ownerId,
        month: _selectedMonth,
        year: _selectedYear,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Rent records generated for ${_months[_selectedMonth - 1]} $_selectedYear'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _markAsPaid(RentPaymentModel rent, RentService rentService) async {
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Mark as Paid?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.emeraldGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '₹${rent.amount.toStringAsFixed(0)} — ${rent.tenantName}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: AppTheme.inputDecoration(
                  'Notes (optional)', Icons.note_outlined),
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppTheme.subtext(context))),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            decoration: BoxDecoration(
              gradient: AppTheme.emeraldGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Confirm Paid',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final error =
          await rentService.markAsPaid(rent.id, notes: notesController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error ?? 'Rent marked as paid!'),
          backgroundColor: error != null ? Colors.red : Colors.green,
        ));
      }
    }
  }

  Future<void> _recordPartialPayment(
      RentPaymentModel rent, RentService rentService) async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Partial Payment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total due: ₹${rent.amount.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                  color: AppTheme.subtext(context), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Unpaid balance will carry to next month.',
              style: GoogleFonts.inter(
                  color: const Color(0xFFF59E0B), fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Amount Received (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Cash partial, UPI…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppTheme.subtext(context))),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Record',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final paid = double.tryParse(amountController.text.trim());
      if (paid == null || paid <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Enter a valid amount'),
              backgroundColor: Colors.red),
        );
        return;
      }

      final remaining = rent.amount - paid;
      final error = await rentService.recordPartialPayment(
        rent.id,
        paidAmount: paid,
        notes: notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error != null
              ? error
              : remaining > 0
                  ? 'Recorded ₹${paid.toStringAsFixed(0)} paid. ₹${remaining.toStringAsFixed(0)} carries to next month.'
                  : 'Full amount paid!'),
          backgroundColor: error != null ? Colors.red : Colors.blue,
        ));
      }
    }
  }

  Future<void> _sendReminder(
      RentPaymentModel rent, RentService rentService) async {
    await rentService.sendRentReminder(rent.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder sent to ${rent.tenantName}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
