import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/errors/app_exception.dart';
import '../../shared/widgets/arise_button.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e is AppException ? e.message : 'Failed to load profile.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              AriseButton(
                label: 'Retry',
                onPressed: () => ref.read(profileProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        data: (me) => RefreshIndicator(
          onRefresh: () => ref.read(profileProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AccountCard(email: me.email, createdAt: me.createdAt),
              const SizedBox(height: 16),
              if (me.profile != null)
                _ProfileSection(
                  displayName: me.profile!.displayName,
                  bio: me.profile!.bio ?? '',
                  timezone: me.profile!.timezone,
                  themePreference: me.profile!.themePreference,
                )
              else
                const _NoProfileCard(),
              const SizedBox(height: 16),
              const _PasswordSection(),
              const SizedBox(height: 16),
              const _DangerZone(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Account card ───────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final String email;
  final String createdAt;

  const _AccountCard({required this.email, required this.createdAt});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final since = DateTime.tryParse(createdAt);
    final sinceStr = since != null
        ? '${_month(since.month)} ${since.day}, ${since.year}'
        : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primary.withValues(alpha: 0.15),
              child: Text(
                email.substring(0, 2).toUpperCase(),
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sinceStr.isNotEmpty)
                    Text(
                      'Member since $sinceStr',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _month(int m) => const [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m];
}

class _NoProfileCard extends StatelessWidget {
  const _NoProfileCard();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Profile not yet set up.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
}

// ── Profile section ────────────────────────────────────────────────────────────

class _ProfileSection extends ConsumerStatefulWidget {
  final String displayName;
  final String bio;
  final String timezone;
  final String themePreference;

  const _ProfileSection({
    required this.displayName,
    required this.bio,
    required this.timezone,
    required this.themePreference,
  });

  @override
  ConsumerState<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<_ProfileSection> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _tzCtrl;
  late String _theme;
  bool _loading = false;
  bool _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.displayName);
    _bioCtrl = TextEditingController(text: widget.bio);
    _tzCtrl = TextEditingController(text: widget.timezone);
    _theme = widget.themePreference;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _tzCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(profileProvider.notifier).updateProfile(
            displayName: _nameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            timezone: _tzCtrl.text.trim(),
            themePreference: _theme,
          );
      if (mounted) {
        setState(() { _saved = true; });
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) setState(() { _saved = false; });
        });
      }
    } on AppException catch (e) {
      if (mounted) setState(() { _error = e.message; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _Field(label: 'Display name', child: TextField(controller: _nameCtrl, decoration: _dec('Hunter name'))),
            const SizedBox(height: 12),
            _Field(
              label: 'Bio',
              child: TextField(
                controller: _bioCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: _dec('A short bio…'),
              ),
            ),
            const SizedBox(height: 12),
            _Field(
              label: 'Timezone',
              child: TextField(controller: _tzCtrl, decoration: _dec('e.g. UTC, America/New_York')),
            ),
            const SizedBox(height: 12),
            _Field(
              label: 'Theme',
              child: Row(
                children: ['dark', 'light', 'system'].map((t) {
                  final selected = _theme == t;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _theme = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? cs.primary
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? cs.primary : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            t[0].toUpperCase() + t.substring(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: cs.error, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            AriseButton(
              label: _saved ? 'Saved!' : 'Save',
              loading: _loading,
              onPressed: _loading ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) =>
      InputDecoration(hintText: hint, isDense: true);
}

// ── Password section ───────────────────────────────────────────────────────────

class _PasswordSection extends ConsumerStatefulWidget {
  const _PasswordSection();

  @override
  ConsumerState<_PasswordSection> createState() => _PasswordSectionState();
}

class _PasswordSectionState extends ConsumerState<_PasswordSection> {
  final _currCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _loading = false;
  bool _saved = false;
  String? _error;

  @override
  void dispose() {
    _currCtrl.dispose();
    _newCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _currCtrl.text.isNotEmpty &&
      _newCtrl.text.length >= 8 &&
      _newCtrl.text == _confCtrl.text;

  Future<void> _save() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(profileProvider.notifier).changePassword(
            currentPassword: _currCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (mounted) {
        _currCtrl.clear();
        _newCtrl.clear();
        _confCtrl.clear();
        setState(() { _saved = true; });
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) setState(() { _saved = false; });
        });
      }
    } on AppException catch (e) {
      if (mounted) setState(() { _error = e.message; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mismatch =
        _confCtrl.text.isNotEmpty && _newCtrl.text != _confCtrl.text;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Security', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _Field(
              label: 'Current password',
              child: TextField(
                controller: _currCtrl,
                obscureText: true,
                decoration: _dec(''),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            _Field(
              label: 'New password',
              child: TextField(
                controller: _newCtrl,
                obscureText: true,
                decoration: _dec('Minimum 8 characters'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            _Field(
              label: 'Confirm new password',
              child: TextField(
                controller: _confCtrl,
                obscureText: true,
                decoration: _dec(''),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (mismatch)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text("Passwords don't match.",
                    style: TextStyle(color: cs.error, fontSize: 12)),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_error!,
                    style: TextStyle(color: cs.error, fontSize: 12)),
              ),
            const SizedBox(height: 16),
            AriseButton(
              label: _saved ? 'Changed!' : 'Change Password',
              loading: _loading,
              onPressed: (_canSave && !_loading) ? _save : null,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) =>
      InputDecoration(hintText: hint, isDense: true);
}

// ── Danger zone ────────────────────────────────────────────────────────────────

class _DangerZone extends ConsumerStatefulWidget {
  const _DangerZone();

  @override
  ConsumerState<_DangerZone> createState() => _DangerZoneState();
}

class _DangerZoneState extends ConsumerState<_DangerZone> {
  bool _expanded = false;
  final _pwCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(profileProvider.notifier).deleteAccount(_pwCtrl.text);
      if (mounted) {
        await ref.read(authProvider.notifier).logout();
      }
    } on AppException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: cs.error, size: 18),
                const SizedBox(width: 8),
                Text('Danger Zone',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: cs.error)),
              ],
            ),
            const SizedBox(height: 12),
            if (!_expanded) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delete account',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                )),
                        Text(
                          'Permanently deactivate your account.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _expanded = true),
                    style: TextButton.styleFrom(foregroundColor: cs.error),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Enter your password to confirm:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pwCtrl,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Password',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.error),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.error, width: 2),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(_error!, style: TextStyle(color: cs.error, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _expanded = false;
                        _pwCtrl.clear();
                        _error = null;
                      }),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AriseButton(
                      label: 'Confirm Delete',
                      isDestructive: true,
                      loading: _loading,
                      onPressed: (_pwCtrl.text.isNotEmpty && !_loading)
                          ? _delete
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Shared label wrapper ───────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final Widget child;

  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
