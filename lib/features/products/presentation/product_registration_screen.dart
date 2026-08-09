import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/content_frame.dart';
import '../domain/product_component.dart';

class ProductRegistrationScreen extends ConsumerStatefulWidget {
  const ProductRegistrationScreen({super.key});

  @override
  ConsumerState<ProductRegistrationScreen> createState() =>
      _ProductRegistrationScreenState();
}

class _ProductRegistrationScreenState
    extends ConsumerState<ProductRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _serial = TextEditingController();
  final _ownerEmail = TextEditingController();
  var _category = 'Laptop';
  DateTime? _purchaseDate;
  DateTime? _warrantyEnd;
  final _components = <NewProductComponent>[];
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    _serial.dispose();
    _ownerEmail.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 3650)),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final productId = await ref.read(productRepositoryProvider).registerProduct(
            name: _name.text,
            brand: _brand.text,
            model: _model.text,
            category: _category,
            serialNumber: _serial.text,
            ownerEmail: _ownerEmail.text,
            components: _components,
            purchaseDate: _purchaseDate,
            warrantyEnd: _warrantyEnd,
          );
      if (mounted) context.go('/passport/$productId');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Register product')),
        body: ContentFrame(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Issue a digital product passport',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The passport ID is generated securely by Cloud Functions.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _Field(controller: _name, label: 'Product name'),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(child: _Field(controller: _brand, label: 'Brand')),
                              const SizedBox(width: 12),
                              Expanded(child: _Field(controller: _model, label: 'Model')),
                            ],
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: const [
                              'Laptop',
                              'Mobile phone',
                              'Tablet',
                              'Television',
                              'Appliance',
                              'Other',
                            ]
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(() => _category = value!),
                          ),
                          const SizedBox(height: 14),
                          _Field(controller: _serial, label: 'Serial number'),
                          const SizedBox(height: 14),
                          _Field(
                            controller: _ownerEmail,
                            label: 'Owner email address',
                            keyboardType: TextInputType.emailAddress,
                            email: true,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _DateField(
                                  label: 'Purchase date',
                                  value: _purchaseDate,
                                  onTap: () async {
                                    final value = await _pickDate(_purchaseDate);
                                    if (value != null) {
                                      setState(() => _purchaseDate = value);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DateField(
                                  label: 'Warranty end',
                                  value: _warrantyEnd,
                                  onTap: () async {
                                    final value = await _pickDate(_warrantyEnd);
                                    if (value != null) {
                                      setState(() => _warrantyEnd = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Original components',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      'Optional parts included when this product was manufactured.',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _addComponent,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add component'),
                              ),
                            ],
                          ),
                          if (_components.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ..._components.asMap().entries.map(
                                  (entry) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.memory_outlined),
                                    title: Text(entry.value.name),
                                    subtitle: Text(entry.value.partNumber),
                                    trailing: IconButton(
                                      tooltip: 'Remove component',
                                      onPressed: () => setState(
                                        () => _components.removeAt(entry.key),
                                      ),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ),
                                ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      label: Text(_saving ? 'Creating passport…' : 'Create passport'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      );

  Future<void> _addComponent() async {
    final component = await showDialog<NewProductComponent>(
      context: context,
      builder: (context) => const _OriginalComponentDialog(),
    );
    if (component != null) setState(() => _components.add(component));
  }
}

class _OriginalComponentDialog extends StatefulWidget {
  const _OriginalComponentDialog();

  @override
  State<_OriginalComponentDialog> createState() =>
      _OriginalComponentDialogState();
}

class _OriginalComponentDialogState extends State<_OriginalComponentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _partNumber = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _partNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add original component'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Component name'),
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'Enter the component name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _partNumber,
                  decoration: const InputDecoration(labelText: 'Part number'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter the part number'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                NewProductComponent(
                  name: _name.text.trim(),
                  partNumber: _partNumber.text.trim(),
                ),
              );
            },
            child: const Text('Add component'),
          ),
        ],
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.email = false,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool email;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return '$label is required';
          if (email && !value.contains('@')) return 'Enter a valid email address';
          return null;
        },
      );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          child: Text(
            value == null
                ? 'Not set'
                : '${value!.day.toString().padLeft(2, '0')}/'
                    '${value!.month.toString().padLeft(2, '0')}/${value!.year}',
          ),
        ),
      );
}
