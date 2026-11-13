import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/models/bill_result.dart';
import 'package:splitease/models/food_item.dart';
import 'package:splitease/models/participant.dart';
import 'package:splitease/services/bill_calculation_service.dart';
import 'package:splitease/utils/money.dart';

Participant person(
  int id,
  String name,
  String price, {
  String qty = '1',
  String item = 'Item',
}) =>
    Participant(
      id: id,
      name: name,
      items: [FoodItem(id: id, name: item, priceText: price, quantityText: qty)],
    );

CalculationOutcome calc(
  List<Participant> people, {
  String tax = '10',
  String service = '5',
  String shared = '0',
}) =>
    const BillCalculationService().calculate(
      participants: people,
      taxText: tax,
      serviceChargeText: service,
      sharedChargesText: shared,
    );

int rp(int rupiah) => rupiah * 100; // rupiah -> cents

void main() {
  group('example scenario from the spec', () {
    late BillResult result;

    setUp(() {
      final outcome = calc(
        [
          person(1, 'Acha', '25000', item: 'Nasi Goreng'),
          person(2, 'Friend 1', '50000', item: 'Pizza'),
          person(3, 'Friend 2', '40000', item: 'Pasta'),
          person(4, 'Friend 3', '10000', item: 'Es Teh'),
        ],
        shared: '10000',
      );
      expect(outcome.isSuccess, isTrue);
      result = outcome.result!;
    });

    test('per-person amounts', () {
      final expected = <List<int>>[
        // subtotal, tax, service, shared, total
        [25000, 2500, 1250, 2500, 31250],
        [50000, 5000, 2500, 2500, 60000],
        [40000, 4000, 2000, 2500, 48500],
        [10000, 1000, 500, 2500, 14000],
      ];
      for (var i = 0; i < expected.length; i++) {
        final p = result.people[i];
        expect(p.subtotalCents, rp(expected[i][0]), reason: p.name);
        expect(p.taxCents, rp(expected[i][1]), reason: p.name);
        expect(p.serviceChargeCents, rp(expected[i][2]), reason: p.name);
        expect(p.sharedChargeCents, rp(expected[i][3]), reason: p.name);
        expect(p.totalCents, rp(expected[i][4]), reason: p.name);
      }
    });

    test('global totals', () {
      expect(result.totalSubtotalCents, rp(125000));
      expect(result.totalTaxCents, rp(12500));
      expect(result.totalServiceChargeCents, rp(6250));
      expect(result.totalSharedCents, rp(10000));
      expect(result.grandTotalCents, rp(153750));
    });

    test('formatted for display', () {
      expect(Money.formatRupiah(result.grandTotalCents), 'Rp153.750');
      expect(Money.formatRupiah(result.people[0].totalCents), 'Rp31.250');
    });
  });

  group('calculation rules', () {
    test('item subtotal = unit price x quantity, summed per person', () {
      final p = Participant(id: 1, name: 'A', items: [
        FoodItem(id: 1, name: 'Tea', priceText: '5000', quantityText: '3'),
        FoodItem(id: 2, name: 'Rice', priceText: '12500.50', quantityText: '2'),
      ]);
      final result = calc([p], tax: '0', service: '0').result!;
      expect(result.people.first.items[0].subtotalCents, rp(15000));
      expect(result.people.first.items[1].subtotalCents, 2500100);
      expect(result.people.first.subtotalCents, 4000100);
    });

    test('tax and service are per person, not split equally', () {
      final result = calc([
        person(1, 'A', '100000'),
        person(2, 'B', '0'),
      ]).result!;
      expect(result.people[0].taxCents, rp(10000));
      expect(result.people[1].taxCents, 0);
      expect(result.people[0].serviceChargeCents, rp(5000));
      expect(result.people[1].serviceChargeCents, 0);
    });

    test('decimal percentages and half-up rounding to the cent', () {
      // 19.99 x 3 = 59.97; 10% = 5.997 -> 6.00
      final r1 = calc([person(1, 'A', '19.99', qty: '3')], service: '0').result!;
      expect(r1.people.first.taxCents, 600);
      // 300 x 7.5% = 22.50
      final r2 = calc([person(1, 'A', '100', qty: '3')], tax: '7.5', service: '0')
          .result!;
      expect(r2.people.first.taxCents, 2250);
    });

    test('shared charges split deterministically and add up exactly', () {
      final shares = BillCalculationService.splitEvenly(1000000, 3);
      expect(shares, [333334, 333333, 333333]);
      expect(shares.fold<int>(0, (a, b) => a + b), 1000000);

      final result = calc(
        [person(1, 'A', '1000'), person(2, 'B', '1000'), person(3, 'C', '1000')],
        shared: '10000',
      ).result!;
      final sharedSum =
          result.people.fold<int>(0, (a, p) => a + p.sharedChargeCents);
      expect(sharedSum, result.totalSharedCents);
      final totalsSum = result.people.fold<int>(0, (a, p) => a + p.totalCents);
      expect(result.grandTotalCents, totalsSum);
    });

    test('0% and 100% boundaries are accepted', () {
      expect(calc([person(1, 'A', '1000')], tax: '0', service: '100').isSuccess,
          isTrue);
      expect(calc([person(1, 'A', '1000')], tax: '100', service: '0').isSuccess,
          isTrue);
    });
  });

  group('validation blocks calculation', () {
    void expectFails(CalculationOutcome o, String contains) {
      expect(o.isSuccess, isFalse);
      expect(o.errors.any((e) => e.contains(contains)), isTrue,
          reason: 'errors were: ${o.errors}');
    }

    test('no participants', () {
      expectFails(calc([]), 'at least one participant');
    });

    test('participant without orders', () {
      expectFails(calc([Participant(id: 1, name: 'A')]), 'A has no orders');
    });

    test('empty item name', () {
      expectFails(calc([person(1, 'A', '1000', item: '  ')]), 'Item name');
    });

    test('invalid prices', () {
      expectFails(calc([person(1, 'A', '-5')]), 'Unit price cannot be negative');
      expectFails(calc([person(1, 'A', '')]), 'Unit price is required');
      expectFails(calc([person(1, 'A', 'abc')]), 'Unit price must be a number');
      expectFails(calc([person(1, 'A', '1.234')]), 'at most 2 decimal');
    });

    test('invalid quantities', () {
      expectFails(calc([person(1, 'A', '1000', qty: '0')]), 'at least 1');
      expectFails(
          calc([person(1, 'A', '1000', qty: '-2')]), 'Quantity cannot be negative');
      expectFails(
          calc([person(1, 'A', '1000', qty: '2.5')]), 'Quantity must be a whole');
      expectFails(calc([person(1, 'A', '1000', qty: '')]), 'Quantity is required');
    });

    test('invalid tax / service / shared', () {
      final p = [person(1, 'A', '1000')];
      expectFails(calc(p, tax: '-1'), 'Tax percentage cannot be negative');
      expectFails(calc(p, tax: '100.01'), 'Tax percentage cannot be greater than 100');
      expectFails(calc(p, tax: '101'), 'Tax percentage cannot be greater than 100');
      expectFails(calc(p, service: '-0.5'),
          'Service charge percentage cannot be negative');
      expectFails(calc(p, service: '150'),
          'Service charge percentage cannot be greater than 100');
      expectFails(calc(p, shared: '-1'), 'Shared charges cannot be negative');
      expectFails(calc(p, tax: ''), 'Tax percentage is required');
    });

    test('participant name rules', () {
      expect(BillCalculationService.validateParticipantName('  ', []),
          'Participant name cannot be empty.');
      expect(BillCalculationService.validateParticipantName('acha', ['Acha']),
          contains('already exists'));
      expect(BillCalculationService.validateParticipantName('Budi', ['Acha']),
          isNull);
    });
  });

  group('formatting', () {
    test('rupiah', () {
      expect(Money.formatRupiah(0), 'Rp0');
      expect(Money.formatRupiah(3125000), 'Rp31.250');
      expect(Money.formatRupiah(125050), 'Rp1.250,50');
      expect(Money.formatRupiah(100000000), 'Rp1.000.000');
    });

    test('percent', () {
      expect(Money.formatPercent(1000), '10%');
      expect(Money.formatPercent(750), '7,5%');
      expect(Money.formatPercent(5), '0,05%');
    });
  });
}
