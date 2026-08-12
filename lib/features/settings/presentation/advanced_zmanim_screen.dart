import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/zmanim_settings_controller.dart';
import '../../../core/models/zmanim/hebcal_zman_field.dart';
import '../../../core/models/zmanim/hebcal_zman_field_labels.dart';
import '../../../core/models/zmanim/zman_calculation_groups.dart';
import '../../../core/models/zmanim/zman_definition.dart';
import '../../../core/models/zmanim/zmanim_configuration.dart';
import '../../../widgets/responsive_center.dart';

/// Lets advanced users customize the Zmanim card beyond the default 12:
/// enable/disable and reorder existing rows, rename a row or swap which
/// real Hebcal calculation/opinion backs it (never silently), and add
/// further Zmanim from Hebcal's actual field set. Every change here takes
/// effect immediately via [zmanimConfigurationProvider] -- there's no
/// separate "save" step.
class AdvancedZmanimScreen extends ConsumerWidget {
  const AdvancedZmanimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(zmanimConfigurationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Zmanim'),
        actions: [
          IconButton(
            tooltip: 'Reset to defaults',
            icon: const Icon(Icons.restore_rounded),
            onPressed: () => _confirmReset(context, ref),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Choose which Zmanim appear on the Weather screen, their names, '
              'which calculation/opinion is used, and their order. Changes apply immediately.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < config.definitions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ZmanRowEditor(
                  key: ValueKey(config.definitions[i].id),
                  definition: config.definitions[i],
                  index: i,
                  count: config.definitions.length,
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _addZman(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add a Zman'),
            ),
            const SizedBox(height: 24),
            Text(
              'Zmanim calculations are provided by Hebcal.com, licensed under CC BY 4.0.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Zmanim to defaults?'),
        content: const Text('This replaces your current Zmanim setup with the approved default 12, discarding any changes.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(zmanimConfigurationProvider.notifier).resetToDefaults();
    }
  }

  Future<void> _addZman(BuildContext context, WidgetRef ref) async {
    final existingIds = ref.read(zmanimConfigurationProvider).definitions.map((d) => d.id).toSet();
    final available = additionalZmanTemplates.where((t) => !existingIds.contains(t.id)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Every Zman Hebcal provides has already been added.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<ZmanDefinition>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Add a Zman', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            for (final template in available)
              ListTile(
                title: Text(template.displayName),
                subtitle: Text(hebcalZmanFieldLabel(template.field)),
                onTap: () => Navigator.of(ctx).pop(template),
              ),
          ],
        ),
      ),
    );

    if (selected != null) {
      await ref.read(zmanimConfigurationProvider.notifier).addDefinition(selected);
    }
  }
}

class _ZmanRowEditor extends ConsumerWidget {
  const _ZmanRowEditor({super.key, required this.definition, required this.index, required this.count});

  final ZmanDefinition definition;
  final int index;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(zmanimConfigurationProvider.notifier);
    final alternatives = alternativesFor(definition.field);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Switch(
                  value: definition.enabled,
                  onChanged: (value) => notifier.setEnabled(definition.id, value),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _rename(context, ref),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Flexible(child: Text(definition.displayName, style: theme.textTheme.titleMedium)),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Move up',
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  onPressed: index > 0 ? () => notifier.reorder(index, index - 1) : null,
                ),
                IconButton(
                  tooltip: 'Move down',
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onPressed: index < count - 1 ? () => notifier.reorder(index, index + 1) : null,
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => notifier.removeDefinition(definition.id),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 60, right: 8),
              child: alternatives.length > 1
                  ? Row(
                      children: [
                        Text('Calculation: ', style: theme.textTheme.bodySmall),
                        Expanded(
                          child: DropdownButton<HebcalZmanField>(
                            isExpanded: true,
                            value: definition.field,
                            underline: const SizedBox.shrink(),
                            items: [
                              for (final field in alternatives)
                                DropdownMenuItem(value: field, child: Text(hebcalZmanFieldLabel(field))),
                            ],
                            onChanged: (field) {
                              if (field != null) notifier.setField(definition.id, field);
                            },
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Calculation: ${hebcalZmanFieldLabel(definition.field)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: definition.displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Zman'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await ref.read(zmanimConfigurationProvider.notifier).setDisplayName(definition.id, result);
    }
  }
}
