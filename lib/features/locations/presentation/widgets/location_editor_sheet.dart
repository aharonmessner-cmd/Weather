import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/location.dart';
import '../../application/locations_controller.dart';

/// A minus sign or a digit or a decimal point — nothing else. Paired with
/// [TextInputType.text] (see the coordinate fields below) rather than
/// `TextInputType.numberWithOptions(signed: true)`: several common Android
/// keyboards ignore the `signed` request and never show a minus key at
/// all, which made negative longitudes (i.e. anywhere in the US) difficult
/// or impossible to type. The plain text keyboard always has one.
final _coordinateInputFormatter = FilteringTextInputFormatter.allow(RegExp(r'[-\d.]'));

/// Advanced/manual add-or-edit form for a saved [Location], entered
/// directly by latitude/longitude. This is the power-user path — normal
/// location entry is "Use My Location" or search, via the entry-point
/// chooser sheet — but it's also the only path for *editing* an
/// already-saved location's coordinates, where entering exact numbers is
/// the point.
///
/// NWS resolves weather purely from coordinates, so latitude/longitude are
/// the only fields that matter functionally — address/description are
/// freeform labels for the user's own reference and are never geocoded or
/// sent anywhere.
class LocationEditorSheet extends ConsumerStatefulWidget {
  const LocationEditorSheet({super.key, this.existing});

  final Location? existing;

  @override
  ConsumerState<LocationEditorSheet> createState() => _LocationEditorSheetState();
}

class _LocationEditorSheetState extends ConsumerState<LocationEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.name);
  late final _latController = TextEditingController(text: widget.existing?.latitude.toString());
  late final _lonController = TextEditingController(text: widget.existing?.longitude.toString());
  late final _addressController = TextEditingController(text: widget.existing?.address);
  late final _descriptionController = TextEditingController(text: widget.existing?.description);
  late bool _isFavorite = widget.existing?.isFavorite ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Location' : 'Advanced: Enter Coordinates',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                ),
                if (!isEditing) ...[
                  const SizedBox(height: 4),
                  Text(
                    'For exact coordinates. Most people should use Search or Use My Location instead.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name', hintText: 'Home, School, Camp…'),
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(labelText: 'Latitude', hintText: 'e.g. 38.8894'),
                        keyboardType: TextInputType.text,
                        inputFormatters: [_coordinateInputFormatter],
                        validator: (value) => _validateCoordinate(value, min: -90, max: 90),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lonController,
                        decoration: const InputDecoration(labelText: 'Longitude', hintText: 'e.g. -77.0352'),
                        keyboardType: TextInputType.text,
                        inputFormatters: [_coordinateInputFormatter],
                        validator: (value) => _validateCoordinate(value, min: -180, max: 180),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tip: find coordinates by dropping a pin in Google Maps or Apple Maps.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address (optional)'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Favorite'),
                  subtitle: const Text('Shown by default on the Weather tab'),
                  value: _isFavorite,
                  onChanged: (value) => setState(() => _isFavorite = value),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(isEditing ? 'Save Changes' : 'Add Location'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateCoordinate(String? value, {required double min, required double max}) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a number';
    if (parsed < min || parsed > max) return 'Must be between $min and $max';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final name = _nameController.text.trim();
    final latitude = double.parse(_latController.text.trim());
    final longitude = double.parse(_lonController.text.trim());
    final address = _addressController.text.trim();
    final description = _descriptionController.text.trim();

    final controller = ref.read(locationsControllerProvider.notifier);
    final existing = widget.existing;
    final result = existing == null
        ? await controller.add(
            name: name,
            latitude: latitude,
            longitude: longitude,
            address: address.isEmpty ? null : address,
            description: description.isEmpty ? null : description,
            isFavorite: _isFavorite,
          )
        : await controller.update(existing.copyWith(
            name: name,
            latitude: latitude,
            longitude: longitude,
            address: address.isEmpty ? null : address,
            description: description.isEmpty ? null : description,
            isFavorite: _isFavorite,
          ));

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    if (result.wasDuplicate) {
      messenger.showSnackBar(
        SnackBar(content: Text('You already have a saved location within 1 km of this — kept "${result.location.name}".')),
      );
    }
  }
}
