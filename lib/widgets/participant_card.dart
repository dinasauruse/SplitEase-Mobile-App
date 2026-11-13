import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../models/participant.dart';
import '../services/bill_calculation_service.dart';
import '../utils/money.dart';
import 'app_card.dart';
import 'auto_id.dart';
import 'food_item_card.dart';

/// One participant with their orders, live subtotal and add/remove actions.
class ParticipantCard extends StatelessWidget {
  const ParticipantCard({
    super.key,
    required this.participant,
    required this.showErrors,
    required this.onRemovePerson,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onChanged,
  });

  final Participant participant;
  final bool showErrors;
  final VoidCallback onRemovePerson;
  final VoidCallback onAddItem;
  final ValueChanged<FoodItem> onRemoveItem;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = participant.id;
    final subtotal = BillCalculationService.liveSubtotalCents(participant);

    return AutoId(
      id: 'person_card_$id',
      container: true,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: AutoId(
                    id: 'person_name_$id',
                    child: Text(
                      participant.name,
                      key: Key('person_name_$id'),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                AutoId(
                  id: 'remove_person_$id',
                  child: IconButton(
                    key: Key('remove_person_$id'),
                    tooltip: 'Remove ${participant.name}',
                    icon: Icon(Icons.delete_outline,
                        color: theme.colorScheme.secondary),
                    onPressed: onRemovePerson,
                  ),
                ),
              ],
            ),
            if (participant.items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('No orders yet.', key: Key('no_orders_$id')),
              ),
            for (final item in participant.items)
              FoodItemCard(
                key: ValueKey<String>('food_item_card_${item.id}'),
                item: item,
                showErrors: showErrors,
                onChanged: onChanged,
                onRemove: () => onRemoveItem(item),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                AutoId(
                  id: 'add_item_$id',
                  child: TextButton.icon(
                    key: Key('add_item_$id'),
                    onPressed: onAddItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add item'),
                  ),
                ),
                const Spacer(),
                const Text('Subtotal: '),
                AutoId(
                  id: 'person_live_subtotal_$id',
                  child: Text(
                    Money.formatRupiah(subtotal),
                    key: Key('person_live_subtotal_$id'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
