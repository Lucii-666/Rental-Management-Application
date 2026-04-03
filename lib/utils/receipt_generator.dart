import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/rent_model.dart';

class ReceiptGenerator {
  static Future<void> shareReceipt(RentPaymentModel rent, {String? ownerName, String? propertyName}) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#059669');
    final lightGreen = PdfColor.fromHex('#F0FDF4');
    final textDark = PdfColor.fromHex('#064E3B');
    final textGrey = PdfColor.fromHex('#6B7280');
    final divider = PdfColor.fromHex('#E5E7EB');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Rent Collect',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Payment Receipt',
                          style: pw.TextStyle(color: PdfColor.fromHex('#CCFFFFFF'), fontSize: 13),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          rent.status == RentStatus.paid ? 'PAID' : 'PARTIAL',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '₹${rent.paidAmount > 0 ? rent.paidAmount.toStringAsFixed(0) : rent.amount.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Receipt details card
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: lightGreen,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: divider),
                ),
                child: pw.Column(
                  children: [
                    _buildRow('Tenant', rent.tenantName, textDark, textGrey),
                    _buildDivider(divider),
                    _buildRow('Room', 'Room ${rent.roomNumber}', textDark, textGrey),
                    if (propertyName != null) ...[
                      _buildDivider(divider),
                      _buildRow('Property', propertyName, textDark, textGrey),
                    ],
                    _buildDivider(divider),
                    _buildRow('Period', rent.monthLabel, textDark, textGrey),
                    _buildDivider(divider),
                    _buildRow('Due Date', _formatDate(rent.dueDate), textDark, textGrey),
                    if (rent.paidDate != null) ...[
                      _buildDivider(divider),
                      _buildRow('Paid On', _formatDate(rent.paidDate!), textDark, textGrey),
                    ],
                    if (ownerName != null) ...[
                      _buildDivider(divider),
                      _buildRow('Received By', ownerName, textDark, textGrey),
                    ],
                    if (rent.notes != null && rent.notes!.isNotEmpty) ...[
                      _buildDivider(divider),
                      _buildRow('Notes', rent.notes!, textDark, textGrey),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Amount breakdown
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: divider),
                ),
                child: pw.Column(
                  children: [
                    _buildAmountRow('Base Rent', rent.baseAmount, textGrey, primaryColor),
                    if (rent.carryForward > 0) ...[
                      pw.SizedBox(height: 8),
                      _buildAmountRow('Previous Due (Carry Forward)', rent.carryForward, textGrey, PdfColor.fromHex('#F59E0B')),
                    ],
                    pw.SizedBox(height: 8),
                    pw.Divider(color: divider),
                    pw.SizedBox(height: 8),
                    _buildAmountRow('Total Due', rent.amount, textDark, textDark, isBold: true),
                    pw.SizedBox(height: 8),
                    _buildAmountRow('Amount Paid', rent.paidAmount > 0 ? rent.paidAmount : rent.amount, textDark, primaryColor, isBold: true),
                    if (rent.status == RentStatus.partiallyPaid) ...[
                      pw.SizedBox(height: 8),
                      _buildAmountRow('Balance (Next Month)', rent.balance, textDark, PdfColor.fromHex('#EF4444'), isBold: true),
                    ],
                  ],
                ),
              ),
              pw.Spacer(),

              // Footer
              pw.Divider(color: divider),
              pw.SizedBox(height: 12),
              pw.Text(
                'This is a computer-generated receipt. Generated by Rent Collect App.',
                style: pw.TextStyle(color: textGrey, fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated on ${_formatDate(DateTime.now())}',
                style: pw.TextStyle(color: textGrey, fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Rent_Receipt_${rent.tenantName.replaceAll(' ', '_')}_${rent.monthLabel.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildRow(String label, String value, PdfColor textDark, PdfColor textGrey) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(color: textGrey, fontSize: 12)),
        pw.Text(value, style: pw.TextStyle(color: textDark, fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildAmountRow(String label, double amount, PdfColor labelColor, PdfColor valueColor, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(color: labelColor, fontSize: 13, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text('₹${amount.toStringAsFixed(0)}', style: pw.TextStyle(color: valueColor, fontSize: 13, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildDivider(PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Divider(color: color, thickness: 0.5),
    );
  }

  static String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
