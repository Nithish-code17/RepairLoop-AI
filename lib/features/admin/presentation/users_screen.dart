import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/domain/app_user.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('User access management')),
        body: ContentFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registered users', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                'Grant technician or administrator access only after identity verification.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: AsyncValueView(
                  value: ref.watch(adminUsersProvider),
                  data: (users) => Card(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _UserRow(user: users[index]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _UserRow extends ConsumerStatefulWidget {
  const _UserRow({required this.user});

  final AppUser user;

  @override
  ConsumerState<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends ConsumerState<_UserRow> {
  var _saving = false;

  Future<void> _changeRole(AppRole role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change access role?'),
        content: Text(
          '${widget.user.displayName} will receive ${role.label} access. '
          'The change is written to Firestore and Firebase custom claims.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm role'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).setRole(widget.user.id, role);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User role updated.')));
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

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        leading: CircleAvatar(
          child: Text(widget.user.displayName.characters.first.toUpperCase()),
        ),
        title: Text(widget.user.displayName),
        subtitle: Text(widget.user.email),
        trailing: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : PopupMenuButton<AppRole>(
                tooltip: 'Change access role',
                onSelected: _changeRole,
                itemBuilder: (context) => AppRole.values
                    .map(
                      (role) => PopupMenuItem(
                        value: role,
                        child: Row(
                          children: [
                            Expanded(child: Text(role.label)),
                            if (role == widget.user.role)
                              const Icon(Icons.check, size: 18),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                child: StatusChip(
                  widget.user.role.label.toUpperCase(),
                  tone: widget.user.role == AppRole.admin ||
                          widget.user.role == AppRole.technician
                      ? StatusTone.warning
                      : StatusTone.neutral,
                ),
              ),
      );
}
