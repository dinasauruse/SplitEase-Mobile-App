import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/main.dart';

void main() {
  void useTallScreen(WidgetTester tester) {
    // Tall viewport so every widget is on screen without scrolling.
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('shows title, defaults and rejects duplicate participants',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const SplitEaseApp());

    expect(find.text('SplitEase'), findsOneWidget);
    expect(find.text('Split bills, stress less.'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('tax_percentage_input'))).controller!.text, '10');
    expect(tester.widget<TextField>(find.byKey(const Key('service_charge_percentage_input'))).controller!.text, '5');
    expect(tester.widget<TextField>(find.byKey(const Key('shared_charges_input'))).controller!.text, '0');

    Future<void> addPerson(String name) async {
      await tester.enterText(find.byKey(const Key('person_name_input')), name);
      await tester.tap(find.byKey(const Key('add_person_button')));
      await tester.pump();
    }

    await addPerson('Acha');
    expect(find.byKey(const Key('person_card_1')), findsOneWidget);

    await addPerson('acha');
    expect(find.byKey(const Key('person_name_input_error')), findsOneWidget);
    expect(find.byKey(const Key('person_card_2')), findsNothing);

    await addPerson('   ');
    expect(textOf(tester, 'person_name_input_error'),
        'Participant name cannot be empty.');
  });

  testWidgets('spec example scenario end to end, then reset', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const SplitEaseApp());

    Future<void> addPersonWithItem(
        int personId, int itemId, String name, String item, String price) async {
      await tester.enterText(find.byKey(const Key('person_name_input')), name);
      await tester.tap(find.byKey(const Key('add_person_button')));
      await tester.pump();
      await tester.tap(find.byKey(Key('add_item_$personId')));
      await tester.pump();
      await tester.enterText(find.byKey(Key('item_name_$itemId')), item);
      await tester.enterText(find.byKey(Key('item_price_$itemId')), price);
      await tester.pump();
    }

    await addPersonWithItem(1, 1, 'Acha', 'Nasi Goreng', '25000');
    await addPersonWithItem(2, 2, 'Friend 1', 'Pizza', '50000');
    await addPersonWithItem(3, 3, 'Friend 2', 'Pasta', '40000');
    await addPersonWithItem(4, 4, 'Friend 3', 'Es Teh', '10000');
    await tester.enterText(find.byKey(const Key('shared_charges_input')), '10000');
    await tester.pump();

    expect(textOf(tester, 'item_subtotal_1'), 'Rp25.000');

    await tester.tap(find.byKey(const Key('calculate_button')));
    await tester.pump();

    expect(textOf(tester, 'person_total_1'), 'Rp31.250');
    expect(textOf(tester, 'person_total_2'), 'Rp60.000');
    expect(textOf(tester, 'person_total_3'), 'Rp48.500');
    expect(textOf(tester, 'person_total_4'), 'Rp14.000');
    expect(textOf(tester, 'person_shared_charge_1'), 'Rp2.500');
    expect(textOf(tester, 'total_tax_result'), 'Rp12.500');
    expect(textOf(tester, 'total_service_charge_result'), 'Rp6.250');
    expect(textOf(tester, 'grand_total_result'), 'Rp153.750');

    await tester.tap(find.byKey(const Key('reset_button')));
    await tester.pump();

    expect(find.byKey(const Key('grand_total_result')), findsNothing);
    expect(find.byKey(const Key('person_card_1')), findsNothing);
    expect(tester.widget<TextField>(find.byKey(const Key('shared_charges_input'))).controller!.text, '0');
  });

  testWidgets('calculate with invalid input shows validation messages',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const SplitEaseApp());

    await tester.tap(find.byKey(const Key('calculate_button')));
    await tester.pump();

    expect(find.byKey(const Key('validation_message')), findsOneWidget);
    expect(textOf(tester, 'validation_message'),
        contains('Add at least one participant.'));
    expect(find.byKey(const Key('grand_total_result')), findsNothing);
  });
}
