import 'package:flutter/material.dart';

import '../models/bill_result.dart';
import '../utils/money.dart';
import 'app_card.dart';
import 'auto_id.dart';

/// Calculation results: one card per participant plus the global totals.
class BillSummary extends StatelessWidget {
  const BillSummary({super.key, required this.result});

  final BillResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Payment summary',
          key: const Key('summary_title'),
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final bill in result.people)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PersonSummary(bill: bill, result: result),
          ),
        _GlobalSummary(result: result),
      ],
    );
  }
}

class _PersonSummary extends StatelessWidget {
  const _PersonSummary({required this.bill, required this.result});

  final PersonBill bill;
  final BillResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = bill.personId;
    return AppCard(
      key: Key('person_summary_$id'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AutoId(
            id: 'person_summary_name_$id',
            child: Text(
              bill.name,
              key: Key('person_summary_name_$id'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          for (final line in bill.items)
            _ResultRow(
              label: '${line.name} × ${line.quantity}',
              labelId: 'result_item_${line.itemId}',
              value: Money.formatRupiah(line.subtotalCents),
              id: 'result_item_subtotal_${line.itemId}',
            ),
          const Divider(height: 20),
          _ResultRow(
            label: 'Subtotal',
            value: Money.formatRupiah(bill.subtotalCents),
            id: 'person_subtotal_$id',
          ),
          _ResultRow(
            label: 'Tax (${Money.formatPercent(result.taxPercentHundredths)})',
            value: Money.formatRupiah(bill.taxCents),
            id: 'person_tax_$id',
          ),
          _ResultRow(
            label:
                'Service charge (${Money.formatPercent(result.servicePercentHundredths)})',
            value: Money.formatRupiah(bill.serviceChargeCents),
            id: 'person_service_charge_$id',
          ),
          _ResultRow(
            label: 'Shared charges',
            value: Money.formatRupiah(bill.sharedChargeCents),
            id: 'person_shared_charge_$id',
          ),
          const Divider(height: 20),
          _ResultRow(
            label: 'Total to pay',
            value: Money.formatRupiah(bill.totalCents),
            id: 'person_total_$id',
            emphasis: true,
          ),
        ],
      ),
    );
  }
}

class _GlobalSummary extends StatelessWidget {
  const _GlobalSummary({required this.result});

  final BillResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      key: const Key('global_summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Table totals',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _ResultRow(
            label: 'Tax percentage',
            value: Money.formatPercent(result.taxPercentHundredths),
            id: 'tax_percentage_result',
          ),
          _ResultRow(
            label: 'Service charge percentage',
            value: Money.formatPercent(result.servicePercentHundredths),
            id: 'service_charge_percentage_result',
          ),
          _ResultRow(
            label: 'Total shared charges',
            value: Money.formatRupiah(result.totalSharedCents),
            id: 'total_shared_charges_result',
          ),
          _ResultRow(
            label: 'Total subtotal',
            value: Money.formatRupiah(result.totalSubtotalCents),
            id: 'total_subtotal_result',
          ),
          _ResultRow(
            label: 'Total tax',
            value: Money.formatRupiah(result.totalTaxCents),
            id: 'total_tax_result',
          ),
          _ResultRow(
            label: 'Total service charge',
            value: Money.formatRupiah(result.totalServiceChargeCents),
            id: 'total_service_charge_result',
          ),
          const Divider(height: 20),
          _ResultRow(
            label: 'Grand total',
            value: Money.formatRupiah(result.grandTotalCents),
            id: 'grand_total_result',
            emphasis: true,
          ),
        ],
      ),
    );
  }
}

/// A label on the left and an identifiable value on the right.
class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.id,
    this.labelId,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final String id;
  final String? labelId;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasis
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.bodyMedium;
    final lid = labelId;
    final labelText = Text(label, key: lid == null ? null : Key(lid), style: style);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: lid == null ? labelText : AutoId(id: lid, child: labelText),
          ),
          const SizedBox(width: 12),
          AutoId(
            id: id,
            child: Text(
              value,
              key: Key(id),
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
