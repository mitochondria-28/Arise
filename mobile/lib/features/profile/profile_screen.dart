import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/theme_provider.dart';
import 'profile_provider.dart';

// ── Solo Leveling palette ──────────────────────────────────────────────────────
const _kBg     = Color(0xFF0A0A0F);
const _kCard   = Color(0xFF1C1C2E);
const _kBorder = Color(0xFF2A2A3E);
const _kInput  = Color(0xFF0D0D1A);
const _kBlue   = Color(0xFF4FC3F7);
const _kGreen  = Color(0xFF34D399);
const _kRed    = Color(0xFFEF4444);
const _kText   = Color(0xFFE2E8F0);
const _kDim    = Color(0xFF64748B);

// ── Shared helpers ─────────────────────────────────────────────────────────────
InputDecoration _inputDec(String hint, {bool counter = false}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _kDim, fontSize: 13),
      filled: true,
      fillColor: _kInput,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kRed),
      ),
      counterStyle: const TextStyle(color: _kDim, fontSize: 10),
      counterText: counter ? null : '',
    );

// ── Screen ─────────────────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(
          children: [
            _ProfileHeader(onBack: () => context.pop()),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: _kBlue, strokeWidth: 2),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: _kRed, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          e is AppException
                              ? e.message
                              : 'Failed to load profile.',
                          style: const TextStyle(
                              color: _kText, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        _DarkButton(
                          label: 'RETRY',
                          color: _kBlue,
                          onPressed: () =>
                              ref.read(profileProvider.notifier).refresh(),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (me) => RefreshIndicator(
                  color: _kBlue,
                  backgroundColor: _kCard,
                  onRefresh: () =>
                      ref.read(profileProvider.notifier).refresh(),
                  child: ListView(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _AccountCard(
                              email: me.email,
                              createdAt: me.createdAt)
                          .animate()
                          .fadeIn(duration: 350.ms),
                      const SizedBox(height: 14),
                      if (me.profile != null)
                        _ProfileSection(
                          displayName: me.profile!.displayName,
                          bio: me.profile!.bio ?? '',
                          timezone: me.profile!.timezone,
                          themePreference:
                              me.profile!.themePreference,
                        ).animate().fadeIn(
                            delay: 80.ms, duration: 350.ms)
                      else
                        const _NoProfileCard()
                            .animate()
                            .fadeIn(delay: 80.ms, duration: 350.ms),
                      const SizedBox(height: 14),
                      const _PasswordSection()
                          .animate()
                          .fadeIn(delay: 160.ms, duration: 350.ms),
                      const SizedBox(height: 14),
                      const _DangerZone()
                          .animate()
                          .fadeIn(delay: 240.ms, duration: 350.ms),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _ProfileHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 14, 16, 16),
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _kText, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 5, height: 5,
                    decoration: const BoxDecoration(
                        color: _kBlue, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'HUNTER PROFILE',
                    style: TextStyle(
                      color: _kBlue, fontSize: 9,
                      fontWeight: FontWeight.w700, letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Profile & Settings',
                style: TextStyle(
                  color: _kText, fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section card wrapper ───────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final List<Widget> children;
  final Color? borderColor;

  const _SectionCard({
    required this.tag,
    required this.tagColor,
    required this.children,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4, height: 4,
                decoration: BoxDecoration(
                    color: tagColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(
                tag,
                style: TextStyle(
                  color: tagColor, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
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
    final since = DateTime.tryParse(createdAt);
    final sinceStr = since != null
        ? 'Since ${_month(since.month)} ${since.year}'
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: _kBlue.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Center(
              child: Text(
                email.substring(0, 2).toUpperCase(),
                style: const TextStyle(
                  color: _kBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(
                    color: _kText, fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (sinceStr.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    sinceStr,
                    style: const TextStyle(
                        color: _kDim, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: _kGreen.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                color: _kGreen, fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

class _NoProfileCard extends StatelessWidget {
  const _NoProfileCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: const Text(
          'Profile not yet set up.',
          style: TextStyle(color: _kDim, fontSize: 13),
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
    _bioCtrl  = TextEditingController(text: widget.bio);
    _tzCtrl   = TextEditingController(text: widget.timezone);
    _theme    = widget.themePreference;
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
    return _SectionCard(
      tag: 'PROFILE',
      tagColor: _kBlue,
      children: [
        _Field(
          label: 'Display Name',
          child: TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: _kText, fontSize: 13),
            decoration: _inputDec('Hunter name'),
          ),
        ),
        const SizedBox(height: 12),
        _Field(
          label: 'Bio',
          child: TextField(
            controller: _bioCtrl,
            maxLines: 3,
            maxLength: 500,
            style: const TextStyle(color: _kText, fontSize: 13),
            decoration: _inputDec('A short bio…', counter: true),
          ),
        ),
        const SizedBox(height: 12),
        _Field(
          label: 'Timezone',
          child: TextField(
            controller: _tzCtrl,
            style: const TextStyle(color: _kText, fontSize: 13),
            decoration: _inputDec('e.g. UTC, America/New_York'),
          ),
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
                    onTap: () {
                      setState(() => _theme = t);
                      ref.read(themeProvider.notifier).setTheme(t);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? _kBlue.withValues(alpha: 0.12)
                            : _kInput,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? _kBlue.withValues(alpha: 0.5)
                              : _kBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t[0].toUpperCase() + t.substring(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected ? _kBlue : _kDim,
                          letterSpacing: 0.3,
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
          const SizedBox(height: 10),
          _ErrorText(_error!),
        ],
        const SizedBox(height: 18),
        _DarkButton(
          label: _saved ? 'SAVED ✓' : 'SAVE PROFILE',
          color: _saved ? _kGreen : _kBlue,
          loading: _loading,
          onPressed: _loading ? null : _save,
        ),
      ],
    );
  }
}

// ── Password section ───────────────────────────────────────────────────────────
class _PasswordSection extends ConsumerStatefulWidget {
  const _PasswordSection();

  @override
  ConsumerState<_PasswordSection> createState() => _PasswordSectionState();
}

class _PasswordSectionState extends ConsumerState<_PasswordSection> {
  final _currCtrl = TextEditingController();
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _loading = false;
  bool _saved   = false;
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
    final mismatch =
        _confCtrl.text.isNotEmpty && _newCtrl.text != _confCtrl.text;

    return _SectionCard(
      tag: 'SECURITY',
      tagColor: _kDim,
      children: [
        _Field(
          label: 'Current Password',
          child: TextField(
            controller: _currCtrl,
            obscureText: true,
            style: const TextStyle(color: _kText, fontSize: 13),
            decoration: _inputDec(''),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        _Field(
          label: 'New Password',
          child: TextField(
            controller: _newCtrl,
            obscureText: true,
            style: const TextStyle(color: _kText, fontSize: 13),
            decoration: _inputDec('Minimum 8 characters'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        _Field(
          label: 'Confirm New Password',
          child: TextField(
            controller: _confCtrl,
            obscureText: true,
            style: const TextStyle(color: _kText, fontSize: 13),
            decoration: _inputDec(''),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (mismatch) ...[
          const SizedBox(height: 8),
          const _ErrorText("Passwords don't match."),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          _ErrorText(_error!),
        ],
        const SizedBox(height: 18),
        _DarkButton(
          label: _saved ? 'CHANGED ✓' : 'CHANGE PASSWORD',
          color: _saved ? _kGreen : _kBlue,
          loading: _loading,
          onPressed: (_canSave && !_loading) ? _save : null,
        ),
      ],
    );
  }
}

// ── Danger zone ────────────────────────────────────────────────────────────────
class _DangerZone extends ConsumerStatefulWidget {
  const _DangerZone();

  @override
  ConsumerState<_DangerZone> createState() => _DangerZoneState();
}

class _DangerZoneState extends ConsumerState<_DangerZone> {
  bool _expanded = false;
  final _pwCtrl  = TextEditingController();
  bool _loading  = false;
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
    return _SectionCard(
      tag: 'DANGER ZONE',
      tagColor: _kRed,
      borderColor: _kRed.withValues(alpha: 0.25),
      children: [
        if (!_expanded) ...[
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: _kRed, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete Account',
                      style: TextStyle(
                        color: _kText, fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Permanently deactivate your account.',
                      style: TextStyle(color: _kDim, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _expanded = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _kRed.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'DELETE',
                    style: TextStyle(
                      color: _kRed, fontSize: 10,
                      fontWeight: FontWeight.w700, letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          const Text(
            'Enter your password to confirm deletion:',
            style: TextStyle(color: _kDim, fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pwCtrl,
            obscureText: true,
            style: const TextStyle(color: _kText, fontSize: 13),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: const TextStyle(color: _kDim, fontSize: 13),
              filled: true,
              fillColor: _kInput,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: _kRed.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kRed, width: 1.5),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            _ErrorText(_error!),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OutlinedDarkButton(
                  label: 'CANCEL',
                  onPressed: () => setState(() {
                    _expanded = false;
                    _pwCtrl.clear();
                    _error = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DarkButton(
                  label: 'CONFIRM DELETE',
                  color: _kRed,
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
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────
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
          style: const TextStyle(
            color: _kDim, fontSize: 10,
            fontWeight: FontWeight.w700, letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(Icons.error_outline, color: _kRed, size: 13),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: _kRed, fontSize: 11)),
          ),
        ],
      );
}

class _DarkButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback? onPressed;

  const _DarkButton({
    required this.label,
    required this.color,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final active = !loading && onPressed != null;
    return GestureDetector(
      onTap: active ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: active ? color : color.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 12, offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_kBg),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: _kBg, fontSize: 11,
                    fontWeight: FontWeight.w800, letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OutlinedDarkButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _OutlinedDarkButton(
      {required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: _kDim, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
