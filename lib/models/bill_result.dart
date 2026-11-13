/// One calculated order line. All money values are integer cents (1/100 Rp).
class ItemLine {
  const ItemLine({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPriceCents,
    required this.subtotalCents,
  });

  final int itemId;
  final String name;
  final int quantity;
  final int unitPriceCents;
  final int subtotalCents;
}

/// The calculated bill for one participant.
class PersonBill {
  const PersonBill({
    required this.personId,
    required this.name,
    required this.items,
    required this.subtotalCents,
    required this.taxCents,
    required this.serviceChargeCents,
    required this.sharedChargeCents,
  });

  final int personId;
  final String name;
  final List<ItemLine> items;
  final int subtotalCents;
  final int taxCents;
  final int serviceChargeCents;
  final int sharedChargeCents;

  int get totalCents =>
      subtotalCents + taxCents + serviceChargeCents + sharedChargeCents;
}

/// The calculated bill for the whole table.
class BillResult {
  const BillResult({
    required this.taxPercentHundredths,
    required this.servicePercentHundredths,
    required this.totalSharedCents,
    required this.people,
  });

  final int taxPercentHundredths;
  final int servicePercentHundredths;
  final int totalSharedCents;
  final List<PersonBill> people;

  int get totalSubtotalCents =>
      people.fold<int>(0, (sum, p) => sum + p.subtotalCents);
  int get totalTaxCents => people.fold<int>(0, (sum, p) => sum + p.taxCents);
  int get totalServiceChargeCents =>
      people.fold<int>(0, (sum, p) => sum + p.serviceChargeCents);

  /// Sum of the individual payments, so displayed totals always add up.
  int get grandTotalCents =>
      people.fold<int>(0, (sum, p) => sum + p.totalCents);
}
