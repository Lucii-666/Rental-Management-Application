import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property_model.dart';
import '../../models/rent_model.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../services/rent_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/receipt_generator.dart';
import 'package:intl/intl.dart';

class RentCollectionScreen extends StatefulWidget {
  const RentCollectionScreen({super.key});

  @override
  State<RentCollectionScreen> createState() => _RentCollectionScreenState();
}

class _RentCollectionScreenState extends State<RentCollectionScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final rentService = Provider.of<RentService>(context, listen: false);
    final ownerId = authService.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('Rent Collection', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: StreamBuilder<List<RentPaymentModel>>(
              stream: rentService.getRentStreamForOwner(
                ownerId: ownerId,
                month: _selectedMonth,
                year: _selectedYear,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final records = snapshot.data ?? [];

                return Column(
                  children: [
                    _buildSummaryBar(records),
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

  Widget _buildMonthSelector() {
    return Container(
      color: AppTheme.card(context),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: AppTheme.primary(context)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedMonth,
                items: List.generate(12, (i) => i + 1)
                    .map((m) => DropdownMenuItem(value: m, child: Text(_months[m - 1])))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMonth = v!),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                items: List.generate(3, (i) => DateTime.now().year - 1 + i)
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (v) => setState(() => _selectedYear = v!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(List<RentPaymentModel> records) {
    final total = records.fold<double>(0, (sum, r) => sum + r.amount);
    final collected = records.fold<double>(0, (sum, r) {
      if (r.status == RentStatus.paid) return sum + r.amount;
      if (r.status == RentStatus.partiallyPaid) return sum + r.paidAmount;
      return sum;
    });
    final pending = total - collected;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary(context), const Color(0xFF9C95FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryStat('Total', '₹${total.toStringAsFixed(0)}', Colors.white),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildSummaryStat('Collected', '₹${collected.toStringAsFixed(0)}', Colors.greenAccent),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildSummaryStat('Pending', '₹${pending.toStringAsFixed(0)}', Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildRentList(List<RentPaymentModel> records, RentService rentService) {
    final sorted = [...records]
      ..sort((a, b) {
        // Sort: overdue first, then pending, then paid
        final order = {RentStatus.overdue: 0, RentStatus.pending: 1, RentStatus.paid: 2};
        return (order[a.status] ?? 1).compareTo(order[b.status] ?? 1);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: sorted.length,
      itemBuilder: (context, index) => _buildRentCard(sorted[index], rentService),
    );
  }

  Widget _buildRentCard(RentPaymentModel rent, RentService rentService) {
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

    final isActionable = rent.status == RentStatus.pending ||
        rent.status == RentStatus.overdue;
    final isPartial = rent.status == RentStatus.partiallyPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary(context).withValues(alpha: 0.1),
                child: Text(
                  rent.tenantName.isNotEmpty ? rent.tenantName[0].toUpperCase() : '?',
                  style: TextStyle(color: AppTheme.primary(context), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rent.tenantName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Room ${rent.roomNumber}',
                        style: TextStyle(color: AppTheme.subtext(context), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Amount + carry forward breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('₹${rent.amount.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.secondary(context))),
                  if (rent.carryForward > 0)
                    Text(
                      '₹${rent.baseAmount.toStringAsFixed(0)} base + ₹${rent.carryForward.toStringAsFixed(0)} due',
                      style: TextStyle(color: Colors.orange, fontSize: 11),
                    ),
                ],
              ),
              Text(
                rent.status == RentStatus.paid
                    ? 'Paid on ${DateFormat('dd MMM').format(rent.paidDate!)}'
                    : 'Due ${DateFormat('dd MMM').format(rent.dueDate)}',
                style: TextStyle(color: statusColor, fontSize: 13),
              ),
            ],
          ),
          // Partial payment info
          if (isPartial) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Paid ₹${rent.paidAmount.toStringAsFixed(0)} — ₹${rent.balance.toStringAsFixed(0)} carries to next month',
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Receipt button for paid / partially paid
          if (rent.status == RentStatus.paid || rent.status == RentStatus.partiallyPaid) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ReceiptGenerator.shareReceipt(rent),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
              label: const Text('Download Receipt'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary(context),
                side: BorderSide(color: AppTheme.primary(context)),
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
          if (isActionable) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendReminder(rent, rentService),
                    icon: const Icon(Icons.notifications_outlined, size: 16),
                    label: const Text('Remind'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _recordPartialPayment(rent, rentService),
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text('Partial'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsPaid(rent, rentService),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Paid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String ownerId, RentService rentService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: AppTheme.subtext(context).withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No rent records for this period',
              style: TextStyle(fontSize: 16, color: AppTheme.subtext(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to generate rent records for all tenants in your properties.',
              style: TextStyle(fontSize: 13, color: AppTheme.subtext(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton(String ownerId) {
    final propertyService = Provider.of<PropertyService>(context, listen: false);
    final rentService = Provider.of<RentService>(context, listen: false);

    return StreamBuilder<List<PropertyModel>>(
      stream: propertyService.getPropertiesStream(ownerId),
      builder: (context, snapshot) {
        final properties = snapshot.data ?? [];
        return FloatingActionButton.extended(
          onPressed: () => _generateRent(ownerId, properties, rentService),
          backgroundColor: AppTheme.primary(context),
          icon: const Icon(Icons.receipt_long, color: Colors.white),
          label: const Text('Generate Rent', style: TextStyle(color: Colors.white)),
        );
      },
    );
  }

  Future<void> _generateRent(
      String ownerId, List<PropertyModel> properties, RentService rentService) async {
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
        title: Text('Mark ${rent.tenantName}\'s Rent as Paid?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Amount: ₹${rent.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Cash received, UPI transfer...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final error = await rentService.markAsPaid(rent.id, notes: notesController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error ?? 'Rent marked as paid!'),
          backgroundColor: error != null ? Colors.red : Colors.green,
        ));
      }
    }
  }

  Future<void> _recordPartialPayment(RentPaymentModel rent, RentService rentService) async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card(context),
        title: Text('Partial Payment — ${rent.tenantName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total due: ₹${rent.amount.toStringAsFixed(0)}',
              style: TextStyle(color: AppTheme.subtext(context), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Unpaid balance will be added to next month\'s rent.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount Received (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Cash partial, UPI...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Record', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final paid = double.tryParse(amountController.text.trim());
      if (paid == null || paid <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount'), backgroundColor: Colors.red),
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

  Future<void> _sendReminder(RentPaymentModel rent, RentService rentService) async {
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
