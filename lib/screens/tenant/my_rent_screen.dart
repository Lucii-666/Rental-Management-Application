import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/rent_model.dart';
import '../../services/auth_service.dart';
import '../../services/rent_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/receipt_generator.dart';

class MyRentScreen extends StatelessWidget {
  const MyRentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final rentService = Provider.of<RentService>(context, listen: false);
    final tenantId = authService.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('My Rent', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentMonthCard(rentService, tenantId),
            const SizedBox(height: 28),
            Text(
              'Payment History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondary(context)),
            ),
            const SizedBox(height: 16),
            _buildPaymentHistory(rentService, tenantId),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMonthCard(RentService rentService, String tenantId) {
    return StreamBuilder<RentPaymentModel?>(
      stream: rentService.getCurrentRentForTenant(tenantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rent = snapshot.data;

        if (rent == null) {
          return _buildNoRentCard(context);
        }

        return _buildCurrentRentCard(context, rent);
      },
    );
  }

  Widget _buildNoRentCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppTheme.softShadow(context)],
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'No rent record for this month',
            style: TextStyle(color: AppTheme.subtext(context), fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Your owner will generate rent records soon.',
            style: TextStyle(color: AppTheme.subtext(context), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentRentCard(BuildContext context, RentPaymentModel rent) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (rent.status) {
      case RentStatus.paid:
        statusColor = Colors.green;
        statusLabel = 'Paid';
        statusIcon = Icons.check_circle_rounded;
      case RentStatus.partiallyPaid:
        statusColor = Colors.blue;
        statusLabel = 'Partially Paid';
        statusIcon = Icons.payments_rounded;
      case RentStatus.overdue:
        statusColor = Colors.red;
        statusLabel = 'Overdue';
        statusIcon = Icons.warning_amber_rounded;
      case RentStatus.pending:
        statusColor = Colors.orange;
        statusLabel = 'Due';
        statusIcon = Icons.schedule_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${statusLabel.toUpperCase()} — ${rent.monthLabel}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '₹${rent.amount.toStringAsFixed(0)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
          ),
          // Carry forward breakdown
          if (rent.carryForward > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white60, size: 14),
                const SizedBox(width: 6),
                Text(
                  '₹${rent.baseAmount.toStringAsFixed(0)} rent + ₹${rent.carryForward.toStringAsFixed(0)} previous due',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
          // Partial payment remaining
          if (rent.status == RentStatus.partiallyPaid) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.payments_outlined, color: Colors.white60, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Paid ₹${rent.paidAmount.toStringAsFixed(0)} — ₹${rent.balance.toStringAsFixed(0)} pending',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Room ${rent.roomNumber}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCardDetail(
                'Due Date',
                DateFormat('dd MMM yyyy').format(rent.dueDate),
              ),
              if (rent.status == RentStatus.paid && rent.paidDate != null)
                _buildCardDetail(
                  'Paid On',
                  DateFormat('dd MMM yyyy').format(rent.paidDate!),
                ),
            ],
          ),
          if (rent.notes != null && rent.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note_outlined, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rent.notes!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Receipt download button for paid or partially paid records
          if (rent.status == RentStatus.paid || rent.status == RentStatus.partiallyPaid) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => ReceiptGenerator.shareReceipt(rent),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Download Receipt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPaymentHistory(RentService rentService, String tenantId) {
    return StreamBuilder<List<RentPaymentModel>>(
      stream: rentService.getRentHistoryForTenant(tenantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = snapshot.data ?? [];

        if (history.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No payment history yet.',
                style: TextStyle(color: Colors.grey.withValues(alpha: 0.6)),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) => _buildHistoryTile(context, history[index]),
        );
      },
    );
  }

  Widget _buildHistoryTile(BuildContext context, RentPaymentModel rent) {
    Color statusColor;
    String statusLabel;

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

    final canDownload = rent.status == RentStatus.paid || rent.status == RentStatus.partiallyPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [AppTheme.softShadow(context)],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_outlined, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rent.monthLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  rent.status == RentStatus.paid && rent.paidDate != null
                      ? 'Paid on ${DateFormat('dd MMM yyyy').format(rent.paidDate!)}'
                      : rent.status == RentStatus.partiallyPaid
                          ? 'Paid ₹${rent.paidAmount.toStringAsFixed(0)} — ₹${rent.balance.toStringAsFixed(0)} due next'
                          : 'Due ${DateFormat('dd MMM yyyy').format(rent.dueDate)}',
                  style: TextStyle(color: AppTheme.subtext(context), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${rent.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              if (canDownload) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => ReceiptGenerator.shareReceipt(rent),
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, size: 13, color: AppTheme.primary(context)),
                      const SizedBox(width: 3),
                      Text('Receipt', style: TextStyle(fontSize: 11, color: AppTheme.primary(context), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
