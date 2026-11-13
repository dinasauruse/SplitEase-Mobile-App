import 'package:flutter/material.dart';

import '../models/bill_result.dart';
import '../models/food_item.dart';
import '../models/participant.dart';
import '../services/bill_calculation_service.dart';
import '../widgets/app_card.dart';
import '../widgets/auto_id.dart';
import '../widgets/bill_summary.dart';
import '../widgets/input_field.dart';
import '../widgets/participant_card.dart';

/// The single screen of the app. State lives here (plain `setState`).
class SplitBillScreen extends StatefulWidget {
  const SplitBillScreen({super.key});

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  static const BillCalculationService _service = BillCalculationService();

  static const String _defaultTax = '10';
  static const String _defaultService = '5';
  static const String _defaultShared = '0';

  final TextEditingController _personName = TextEditingController();
  final TextEditingController _tax = TextEditingController(text: _defaultTax);
  final TextEditingController _serviceCharge =
      TextEditingController(text: _defaultService);
  final TextEditingController _shared =
      TextEditingController(text: _defaultShared);

  final List<Participant> _participants = <Participant>[];
  int _nextPersonId = 1;
  int _nextItemId = 1;

  /// True after a failed calculation: empty/required fields then show errors
  /// too (fields with invalid text always show their error).
  bool _showErrors = false;
  String? _personNameError;
  List<String> _messages = const <String>[];
  BillResult? _result;

  @override
  void dispose() {
    _personName.dispose();
    _tax.dispose();
    _serviceCharge.dispose();
    _shared.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ actions

  void _addPerson() {
    final name = _personName.text.trim();
    final error = BillCalculationService.validateParticipantName(
      name,
      _participants.map((p) => p.name),
    );
    setState(() {
      if (error != null) {
        _personNameError = error;
        return;
      }
      _participants.add(Participant(id: _nextPersonId++, name: name));
      _personName.clear();
      _personNameError = null;
    });
  }

  void _removePerson(Participant person) {
    setState(() => _participants.remove(person));
  }

  void _addItem(Participant person) {
    setState(() => person.items.add(FoodItem(id: _nextItemId++)));
  }

  void _removeItem(Participant person, FoodItem item) {
    setState(() => person.items.remove(item));
  }

  void _refresh() => setState(() {});

  void _calculate() {
    FocusScope.of(context).unfocus();
    final outcome = _service.calculate(
      participants: _participants,
      taxText: _tax.text,
      serviceChargeText: _serviceCharge.text,
      sharedChargesText: _shared.text,
    );
    setState(() {
      _showErrors = !outcome.isSuccess;
      _messages = outcome.errors;
      // An invalid attempt clears the previous result so stale numbers are
      // never shown next to error messages.
      _result = outcome.result;
    });
  }

  void _reset() {
    FocusScope.of(context).unfocus();
    setState(() {
      _participants.clear();
      _nextPersonId = 1;
      _nextItemId = 1;
      _personName.clear();
      _tax.text = _defaultTax;
      _serviceCharge.text = _defaultService;
      _shared.text = _defaultShared;
      _showErrors = false;
      _personNameError = null;
      _messages = const <String>[];
      _result = null;
    });
  }

  String? _visible(String raw, String? error) =>
      (raw.trim().isNotEmpty || _showErrors) ? error : null;

  // -------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final result = _result;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header
                  Text(
                    'SplitEase',
                    key: const Key('app_title'),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Split bills, stress less.',
                    key: const Key('app_subtitle'),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),

                  // 2. Participants
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle(theme, 'Participants'),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: InputField(
                                id: 'person_name_input',
                                label: 'Participant name',
                                controller: _personName,
                                textInputAction: TextInputAction.done,
                                errorText: _personNameError,
                                onChanged: (_) {
                                  if (_personNameError != null) {
                                    setState(() => _personNameError = null);
                                  }
                                },
                                onSubmitted: (_) => _addPerson(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            AutoId(
                              id: 'add_person_button',
                              child: FilledButton.icon(
                                key: const Key('add_person_button'),
                                onPressed: _addPerson,
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text('Add'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 56),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_participants.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'No participants yet. Add someone to start.',
                              key: Key('empty_participants_hint'),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 3. Individual order cards
                  if (_participants.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionTitle(theme, 'Orders'),
                    for (final person in _participants)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ParticipantCard(
                          key: Key('person_card_${person.id}'),
                          participant: person,
                          showErrors: _showErrors,
                          onRemovePerson: () => _removePerson(person),
                          onAddItem: () => _addItem(person),
                          onRemoveItem: (item) => _removeItem(person, item),
                          onChanged: _refresh,
                        ),
                      ),
                  ],
                  const SizedBox(height: 20),

                  // 4 + 5. Tax, service charge, shared charges
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle(theme, 'Charges'),
                        const SizedBox(height: 12),
                        InputField(
                          id: 'tax_percentage_input',
                          label: 'Tax percentage',
                          suffixText: '%',
                          controller: _tax,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          inputFormatters: InputFormats.numeric,
                          errorText: _visible(
                            _tax.text,
                            BillCalculationService.validatePercentage(
                                _tax.text, 'Tax percentage'),
                          ),
                          onChanged: (_) => _refresh(),
                        ),
                        const SizedBox(height: 12),
                        InputField(
                          id: 'service_charge_percentage_input',
                          label: 'Service charge percentage',
                          suffixText: '%',
                          controller: _serviceCharge,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          inputFormatters: InputFormats.numeric,
                          errorText: _visible(
                            _serviceCharge.text,
                            BillCalculationService.validatePercentage(
                                _serviceCharge.text,
                                'Service charge percentage'),
                          ),
                          onChanged: (_) => _refresh(),
                        ),
                        const SizedBox(height: 12),
                        InputField(
                          id: 'shared_charges_input',
                          label: 'Shared charges (split equally)',
                          prefixText: 'Rp ',
                          controller: _shared,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          inputFormatters: InputFormats.numeric,
                          errorText: _visible(
                            _shared.text,
                            BillCalculationService.validateSharedCharges(
                                _shared.text),
                          ),
                          onChanged: (_) => _refresh(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. Calculate + validation messages
                  AutoId(
                    id: 'calculate_button',
                    child: FilledButton(
                      key: const Key('calculate_button'),
                      onPressed: _calculate,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Calculate'),
                    ),
                  ),
                  if (_messages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ValidationBanner(messages: _messages),
                  ],

                  // 7 + 8. Results and grand total
                  if (result != null) ...[
                    const SizedBox(height: 24),
                    BillSummary(result: result),
                  ],

                  // 9. Reset
                  const SizedBox(height: 24),
                  AutoId(
                    id: 'reset_button',
                    child: OutlinedButton(
                      key: const Key('reset_button'),
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: scheme.secondary,
                        side: BorderSide(color: scheme.secondary),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) => Text(
        text,
        style:
            theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      );
}

class _ValidationBanner extends StatelessWidget {
  const _ValidationBanner({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(Icons.error_outline, color: scheme.error),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AutoId(
              id: 'validation_message',
              child: Text(
                messages.join('\n'),
                key: const Key('validation_message'),
                style: TextStyle(color: scheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
