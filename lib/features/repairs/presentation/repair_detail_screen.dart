import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/domain/app_user.dart';
import '../../products/domain/product_component.dart';
import '../domain/repair_case.dart';

class RepairDetailScreen extends ConsumerWidget {
  const RepairDetailScreen({required this.repairId, super.key});

  final String repairId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Repair case')),
        body: ContentFrame(
          child: AsyncValueView(
            value: ref.watch(repairsProvider),
            data: (repairs) {
              RepairCase? repair;
              for (final item in repairs) {
                if (item.id == repairId) repair = item;
              }
              if (repair == null) {
                return const Center(child: Text('Repair case not found.'));
              }
              final role = ref.watch(currentProfileProvider).asData?.value?.role;
              return _RepairContent(repair: repair, role: role);
            },
          ),
        ),
      );
}

class _RepairContent extends ConsumerStatefulWidget {
  const _RepairContent({required this.repair, required this.role});

  final RepairCase repair;
  final AppRole? role;

  @override
  ConsumerState<_RepairContent> createState() => _RepairContentState();
}

class _RepairContentState extends ConsumerState<_RepairContent> {
  late RepairStatus _status;
  late final TextEditingController _notes;
  var _saving = false;

  static const _nextStatuses = <RepairStatus, List<RepairStatus>>{
    RepairStatus.requested: [RepairStatus.accepted, RepairStatus.cancelled],
    RepairStatus.accepted: [RepairStatus.inspecting, RepairStatus.cancelled],
    RepairStatus.inspecting: [
      RepairStatus.awaitingParts,
      RepairStatus.repairing,
      RepairStatus.cancelled,
    ],
    RepairStatus.awaitingParts: [RepairStatus.repairing, RepairStatus.cancelled],
    RepairStatus.repairing: [RepairStatus.completed, RepairStatus.cancelled],
    RepairStatus.completed: [],
    RepairStatus.cancelled: [],
  };

  @override
  void initState() {
    super.initState();
    _status = widget.repair.status;
    _notes = TextEditingController(text: widget.repair.technicianNotes ?? '');
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _RepairContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repair.status != widget.repair.status) {
      _status = widget.repair.status;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(repairRepositoryProvider).updateStatus(
            repairId: widget.repair.id,
            status: _status,
            technicianNotes: _notes.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repair case updated.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _recordReplacement() async {
    final components =
        ref.read(componentsProvider(widget.repair.productId)).asData?.value ??
            const <ProductComponent>[];
    final replacement = await showDialog<_ReplacementInput>(
      context: context,
      builder: (context) => _ReplacementDialog(components: components),
    );
    if (replacement == null) return;
    try {
      await ref.read(repairRepositoryProvider).recordComponentReplacement(
            repairId: widget.repair.id,
            oldComponentId: replacement.oldComponentId,
            name: replacement.name,
            partNumber: replacement.partNumber,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Replacement component recorded.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repair = widget.repair;
    final canEdit = widget.role == AppRole.technician || widget.role == AppRole.admin;
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        repair.issueSummary,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    StatusChip(
                      repair.status.label.toUpperCase(),
                      tone: repair.status == RepairStatus.completed
                          ? StatusTone.success
                          : StatusTone.warning,
                    ),
                  ],
                ),
                const Divider(height: 30),
                _Info(label: 'Case ID', value: repair.id),
                _Info(label: 'Product ID', value: repair.productId),
                _Info(
                  label: 'Created',
                  value: DateFormat('dd MMM yyyy, h:mm a').format(repair.createdAt),
                ),
                _Info(
                  label: 'Last updated',
                  value: DateFormat('dd MMM yyyy, h:mm a').format(repair.updatedAt),
                  last: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Technician update', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  canEdit
                      ? 'Record the verified service stage and concise repair notes.'
                      : 'Updates from the assigned technician appear here.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<RepairStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Repair status'),
                  items: <RepairStatus>{
                    widget.repair.status,
                    ...?_nextStatuses[widget.repair.status],
                  }
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: canEdit
                      ? (value) => setState(() => _status = value!)
                      : null,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _notes,
                  enabled: canEdit,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Inspection and repair notes',
                    hintText: 'Record the verified fault, work performed and test result.',
                  ),
                ),
                if (canEdit) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _recordReplacement,
                        icon: const Icon(Icons.memory_outlined, size: 18),
                        label: const Text('Record replacement part'),
                      ),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Saving…' : 'Save repair update'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ReplacementInput {
  const _ReplacementInput({
    required this.name,
    required this.partNumber,
    this.oldComponentId,
  });

  final String name;
  final String partNumber;
  final String? oldComponentId;
}

class _ReplacementDialog extends StatefulWidget {
  const _ReplacementDialog({required this.components});

  final List<ProductComponent> components;

  @override
  State<_ReplacementDialog> createState() => _ReplacementDialogState();
}

class _ReplacementDialogState extends State<_ReplacementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _partNumber = TextEditingController();
  String _oldComponentId = '';

  @override
  void dispose() {
    _name.dispose();
    _partNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Record replacement component'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _oldComponentId,
                  decoration: const InputDecoration(
                    labelText: 'Component being replaced (optional)',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('No existing component selected'),
                    ),
                    ...widget.components
                        .where((component) => component.replacedAt == null)
                        .map(
                          (component) => DropdownMenuItem<String>(
                            value: component.id,
                            child: Text(component.name),
                          ),
                        ),
                  ],
                  onChanged: (value) =>
                      setState(() => _oldComponentId = value ?? ''),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'New component name'),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.of(context).pop(
                _ReplacementInput(
                  name: _name.text.trim(),
                  partNumber: _partNumber.text.trim(),
                  oldComponentId:
                      _oldComponentId.isEmpty ? null : _oldComponentId,
                ),
              );
            },
            child: const Text('Record component'),
          ),
        ],
      );
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFDCE2E7))),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}
