import 'package:flutter/material.dart';

/// Single place that attaches a stable automation identifier to a widget.
///
/// Flutter `Key`s only exist inside Flutter (widget tests / flutter_driver);
/// they are NOT visible to Appium or Katalon. `Semantics.identifier` is what
/// the Android accessibility bridge publishes (as `resource-id`), so every
/// automation id in this app goes through this widget. Widgets that need to be
/// found in Flutter widget tests additionally carry `Key(id)`.
///
/// If Appium Inspector shows the id on a different node than expected, this is
/// the only place that needs to change (for example `container: true`, or
/// wrapping in `MergeSemantics`).
class AutoId extends StatelessWidget {
  const AutoId({
    super.key,
    required this.id,
    required this.child,
    this.container = false,
  });

  final String id;
  final Widget child;
  final bool container;

  @override
  Widget build(BuildContext context) {
    return Semantics(identifier: id, container: container, child: child);
  }
}
