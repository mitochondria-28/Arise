import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_state.dart';

// ── Solo Leveling palette ──────────────────────────────────────────────────────
const _kBg     = Color(0xFF0A0A0F);
const _kCard   = Color(0xFF1C1C2E);
const _kBorder = Color(0xFF2A2A3E);
const _kInput  = Color(0xFF0D0D1A);
const _kBlue   = Color(0xFF4FC3F7);
const _kRed    = Color(0xFFEF4444);
const _kText   = Color(0xFFE2E8F0);
const _kDim    = Color(0xFF64748B);

const _kRememberMe = 'arise_remember_me';
const _kSavedEmail = 'arise_saved_email';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_kRememberMe) ?? false;
    if (remember) {
      final savedEmail = prefs.getString(_kSavedEmail) ?? '';
      if (mounted) {
        setState(() {
          _rememberMe = true;
          _emailCtrl.text = savedEmail;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .login(_emailCtrl.text.trim(), _passCtrl.text);
      if (ref.read(authProvider).status == AuthStatus.authenticated) {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setBool(_kRememberMe, true);
          await prefs.setString(_kSavedEmail, _emailCtrl.text.trim());
        } else {
          await prefs.remove(_kRememberMe);
          await prefs.remove(_kSavedEmail);
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _field({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kDim, fontSize: 13),
        prefixIcon: Icon(icon, color: _kDim, size: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: _kInput,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kRed, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _kRed, fontSize: 11),
      );

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Hero ─────────────────────────────────────────────
                      const _Hero().animate().fadeIn(duration: 500.ms),
                      const SizedBox(height: 36),

                      // ── Form card ─────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: _kCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Section label
                            Row(
                              children: [
                                Container(
                                  width: 4, height: 4,
                                  decoration: const BoxDecoration(
                                    color: _kBlue, shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                const Text(
                                  'CREDENTIALS',
                                  style: TextStyle(
                                    color: _kBlue, fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Error banner
                            if (auth.error != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _kRed.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _kRed.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                        Icons.warning_amber_rounded,
                                        color: _kRed, size: 14),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        auth.error!,
                                        style: const TextStyle(
                                            color: _kRed, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              style: const TextStyle(
                                  color: _kText, fontSize: 14),
                              decoration: _field(
                                label: 'Email',
                                icon: Icons.alternate_email_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (!v.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              style: const TextStyle(
                                  color: _kText, fontSize: 14),
                              decoration: _field(
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                suffix: GestureDetector(
                                  onTap: () =>
                                      setState(() => _obscure = !_obscure),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _kDim, size: 18,
                                    ),
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (v.length < 8) {
                                  return 'At least 8 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Remember me
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _rememberMe = !_rememberMe),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20, height: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(
                                          () => _rememberMe = v ?? false),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      activeColor: _kBlue,
                                      checkColor: _kBg,
                                      side: const BorderSide(
                                          color: _kBorder, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Remember me',
                                    style: TextStyle(
                                        color: _kDim, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Submit
                            _EnterButton(
                                loading: _loading, onPressed: _submit),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 150.ms, duration: 400.ms)
                          .slideY(begin: 0.06, end: 0),

                      const SizedBox(height: 30),

                      // ── Footer ────────────────────────────────────────────
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'NEW HUNTER? ',
                              style: TextStyle(
                                  color: _kDim, fontSize: 11,
                                  letterSpacing: 1.2),
                            ),
                            Text(
                              'CREATE ACCOUNT',
                              style: TextStyle(
                                color: _kBlue, fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 280.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero section ───────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Portal icon with glow
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _kBlue.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
                color: _kBlue.withValues(alpha: 0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: _kBlue.withValues(alpha: 0.18),
                  blurRadius: 28, spreadRadius: 2),
            ],
          ),
          child: const Icon(Icons.shield_outlined, color: _kBlue, size: 32),
        ),
        const SizedBox(height: 22),

        // ARISE wordmark with flanking lines
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                width: 28, height: 1,
                color: _kBlue.withValues(alpha: 0.35)),
            const SizedBox(width: 10),
            const Text(
              'ARISE',
              style: TextStyle(
                color: _kBlue, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 4.5,
              ),
            ),
            const SizedBox(width: 10),
            Container(
                width: 28, height: 1,
                color: _kBlue.withValues(alpha: 0.35)),
          ],
        ),
        const SizedBox(height: 12),

        const Text(
          'Welcome Back, Hunter',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _kText, fontSize: 26,
            fontWeight: FontWeight.w800, letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Continue your ascent to the top',
          textAlign: TextAlign.center,
          style: TextStyle(color: _kDim, fontSize: 13),
        ),
      ],
    );
  }
}

// ── Enter system button ────────────────────────────────────────────────────────
class _EnterButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _EnterButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: loading ? _kBlue.withValues(alpha: 0.5) : _kBlue,
          borderRadius: BorderRadius.circular(12),
          boxShadow: loading
              ? null
              : [
                  BoxShadow(
                    color: _kBlue.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_kBg),
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ENTER SYSTEM',
                      style: TextStyle(
                        color: _kBg, fontSize: 12,
                        fontWeight: FontWeight.w800, letterSpacing: 2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: _kBg, size: 16),
                  ],
                ),
        ),
      ),
    );
  }
}
