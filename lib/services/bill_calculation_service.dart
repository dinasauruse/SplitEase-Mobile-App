import '../models/bill_result.dart';
import '../models/food_item.dart';
import '../models/participant.dart';
import '../utils/money.dart';

/// Outcome of a calculation attempt: either a result or a list of messages.
class CalculationOutcome {
  const CalculationOutcome.success(this.result)
      : errors = const <String>[];
  const CalculationOutcome.failure(this.errors) : result = null;

  final BillResult? result;
  final List<String> errors;

  bool get isSuccess => result != null;
}

/// Pure business logic: validation and bill calculation. No Flutter imports.
class BillCalculationService {
  const BillCalculationService();

  // ---------------------------------------------------------------- validators
  // Used by the UI for per-field messages and by [calculate] for the summary,
  // so both always agree.

  static String? validateParticipantName(
    String raw,
    Iterable<String> existingNames,
  ) {
    final name = raw.trim();
    if (name.isEmpty) return 'Participant name cannot be empty.';
    final lower = name.toLowerCase();
    final duplicate = existingNames.any((e) => e.trim().toLowerCase() == lower);
    if (duplicate) return 'Participant "$name" already exists.';
    return null;
  }

  static String? validateItemName(String raw) =>
      raw.trim().isEmpty ? 'Item name cannot be empty.' : null;

  static String? validateUnitPrice(String raw) =>
      Money.parseMoney(raw, 'Unit price', maxWholeDigits: 8).error;

  static String? validateQuantity(String raw) => Money.parseQuantity(raw).error;

  static String? validatePercentage(String raw, String label) =>
      Money.parsePercent(raw, label).error;

  static String? validateSharedCharges(String raw) =>
      Money.parseMoney(raw, 'Shared charges', maxWholeDigits: 10).error;

  // ------------------------------------------------------------ live subtotals

  /// Subtotal of one item for live display; 0 while price/quantity are invalid.
  static int liveItemSubtotalCents(FoodItem item) {
    final price = Money.parseMoney(item.priceText, 'Unit price',
        maxWholeDigits: 8);
    final qty = Money.parseQuantity(item.quantityText);
    if (!price.isValid || !qty.isValid) return 0;
    return price.value! * qty.value!;
  }

  static int liveSubtotalCents(Participant participant) => participant.items
      .fold<int>(0, (sum, item) => sum + liveItemSubtotalCents(item));

  // --------------------------------------------------------------- calculation

  /// Splits [totalCents] into [count] shares that add up exactly to the total.
  /// The remainder (in cents) goes one cent at a time to the first
  /// participants in list order, so the result is deterministic.
  static List<int> splitEvenly(int totalCents, int count) {
    if (count <= 0) throw ArgumentError.value(count, 'count', 'must be > 0');
    final base = totalCents ~/ count;
    final remainder = totalCents % count;
    return List<int>.generate(count, (i) => base + (i < remainder ? 1 : 0));
  }

  CalculationOutcome calculate({
    required List<Participant> participants,
    required String taxText,
    required String serviceChargeText,
    required String sharedChargesText,
  }) {
    final errors = <String>[];

    if (participants.isEmpty) errors.add('Add at least one participant.');

    final tax = Money.parsePercent(taxText, 'Tax percentage');
    final service = Money.parsePercent(serviceChargeText, 'Service charge percentage');
    final shared =
        Money.parseMoney(sharedChargesText, 'Shared charges', maxWholeDigits: 10);
    for (final r in [tax, service, shared]) {
      if (!r.isValid) errors.add(r.error!);
    }

    final linesByPerson = <List<ItemLine>>[];
    for (final person in participants) {
      final lines = <ItemLine>[];
      if (person.items.isEmpty) errors.add('${person.name} has no orders.');
      for (var i = 0; i < person.items.length; i++) {
        final item = person.items[i];
        final prefix = '${person.name}, item ${i + 1}: ';
        final nameError = validateItemName(item.name);
        final price =
            Money.parseMoney(item.priceText, 'Unit price', maxWholeDigits: 8);
        final qty = Money.parseQuantity(item.quantityText);
        if (nameError != null) errors.add('$prefix$nameError');
        if (!price.isValid) errors.add('$prefix${price.error}');
        if (!qty.isValid) errors.add('$prefix${qty.error}');
        if (nameError == null && price.isValid && qty.isValid) {
          lines.add(ItemLine(
            itemId: item.id,
            name: item.name.trim(),
            quantity: qty.value!,
            unitPriceCents: price.value!,
            subtotalCents: price.value! * qty.value!,
          ));
        }
      }
      linesByPerson.add(lines);
    }

    if (errors.isNotEmpty) return CalculationOutcome.failure(errors);

    final sharedShares = splitEvenly(shared.value!, participants.length);
    final people = <PersonBill>[];
    for (var i = 0; i < participants.length; i++) {
      final lines = linesByPerson[i];
      final subtotal = lines.fold<int>(0, (sum, l) => sum + l.subtotalCents);
      people.add(PersonBill(
        personId: participants[i].id,
        name: participants[i].name,
        items: lines,
        subtotalCents: subtotal,
        taxCents: Money.percentOf(subtotal, tax.value!),
        serviceChargeCents: Money.percentOf(subtotal, service.value!),
        sharedChargeCents: sharedShares[i],
      ));
    }

    return CalculationOutcome.success(BillResult(
      taxPercentHundredths: tax.value!,
      servicePercentHundredths: service.value!,
      totalSharedCents: shared.value!,
      people: people,
    ));
  }
}
