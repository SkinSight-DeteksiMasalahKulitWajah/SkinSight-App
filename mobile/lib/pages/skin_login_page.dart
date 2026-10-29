
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../data/auth_service.dart';
import '../models/auth_session.dart';
import '../theme/skin_theme.dart';
import '../widgets/skin_page_background.dart';
import '../widgets/skin_ui.dart';

class SkinLoginPage extends StatefulWidget {
  const SkinLoginPage({super.key, this.initialRegisterMode = false});

  final bool initialRegisterMode;

  @override
  State<SkinLoginPage> createState() => _SkinLoginPageState();
}

class _SkinLoginPageState extends State<SkinLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(text: 'alea@skinsight.id');
  final _passwordController = TextEditingController(text: 'skinsight123');
  final _scrollController = ScrollController();

  bool _obscurePassword = true;
  late bool _registerMode;
  bool _busy = false;
  bool _googleBusy = false;

  @override
  void initState() {
    super.initState();
    _registerMode = widget.initialRegisterMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthService>();
      if (_registerMode) {
        await auth.signUp(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await auth.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      if (!mounted) return;
      AuthSession.instance.signIn();
      final destination = _destinationAfterAuthentication;
      Navigator.of(context).pushNamedAndRemoveUntil(destination, (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _googleBusy = true;
    });
    try {
      await context.read<AuthService>().signInWithGoogle();
      if (!mounted) return;
      AuthSession.instance.signIn();
      final destination = _destinationAfterAuthentication;
      Navigator.of(context).pushNamedAndRemoveUntil(destination, (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _googleBusy = false;
        });
      }
    }
  }

  String get _destinationAfterAuthentication =>
      _registerMode || !AuthSession.instance.hasCompletedOnboarding
          ? '/onboarding'
          : '/home';

  void _toggleMode() {
    setState(() {
      _registerMode = !_registerMode;
      _formKey.currentState?.reset();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkinTokens.background,
      body: SkinPageBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 350;
                  return SingleChildScrollView(
                    key: const Key('login-scroll'),
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 20,
                      8,
                      compact ? 16 : 20,
                      24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _LoginTopBar(),
                          const SizedBox(height: 16),
                          SkinReveal(
                            child: _LoginVisualHero(
                              compact: compact,
                              registerMode: _registerMode,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SkinReveal(
                            delay: const Duration(milliseconds: 90),
                            child: _buildFormCard(compact),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(bool compact) {
    return SkinGlass(
      radius: SkinTokens.radiusXl,
      color: SkinTokens.glass,
      borderColor: Colors.white,
      shadows: SkinTokens.shadowsLifted,
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 20,
        compact ? 20 : 22,
        compact ? 16 : 20,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: SkinTokens.medium,
            switchInCurve: Curves.easeOutCubic,
            child: Column(
              key: ValueKey(_registerMode),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _registerMode
                      ? 'Buat akun SkinSight'
                      : 'Selamat datang kembali',
                  style: TextStyle(
                    fontFamily: SkinTokens.serif,
                    color: SkinTokens.ink,
                    fontSize: compact ? 30 : 34,
                    height: 1.05,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _registerMode
                      ? 'Mulai kenali kondisi kulitmu dengan akun baru.'
                      : 'Masuk untuk melanjutkan perjalanan kulitmu.',
                  style: const TextStyle(
                    color: SkinTokens.muted,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 18 : 22),
          if (!_registerMode) ...[
            _GoogleButton(
              onTap: _continueWithGoogle,
              busy: _googleBusy,
            ),
            const SizedBox(height: 16),
            const _OrDivider(),
            const SizedBox(height: 16),
          ],
          if (_registerMode) ...[
            _AuthField(
              fieldKey: const Key('register-name'),
              controller: _nameController,
              label: 'Nama lengkap',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama perlu diisi.'
                  : null,
            ),
            const SizedBox(height: 12),
          ],
          _AuthField(
            fieldKey: const Key('login-email'),
            controller: _emailController,
            label: 'Alamat email',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) {
                return 'Email perlu diisi.';
              }
              if (!email.contains('@')) {
                return 'Masukkan alamat email yang valid.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _AuthField(
            fieldKey: const Key('login-password'),
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
              key: const Key('login-password-visibility'),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              tooltip: _obscurePassword
                  ? 'Tampilkan password'
                  : 'Sembunyikan password',
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: SkinTokens.muted,
              ),
            ),
            validator: (value) {
              if ((value ?? '').length < 6) {
                return 'Password minimal 6 karakter.';
              }
              return null;
            },
          ),
          if (_registerMode) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: SkinTokens.muted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Gunakan minimal 6 karakter.',
                    style: TextStyle(color: SkinTokens.muted, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: compact ? 18 : 20),
          _PrimaryAuthButton(
            label: _busy
                ? 'Memproses...'
                : _registerMode
                    ? 'Daftar'
                    : 'Masuk',
            busy: _busy && !_googleBusy,
            onTap: _busy ? () {} : _submit,
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _registerMode ? 'Sudah punya akun?' : 'Belum punya akun?',
                style: const TextStyle(color: SkinTokens.muted, fontSize: 14),
              ),
              TextButton(
                key: const Key('login-register-toggle'),
                onPressed: _toggleMode,
                child: Text(
                  _registerMode ? 'Masuk' : 'Daftar',
                  style: const TextStyle(
                    color: SkinTokens.ink,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const _LoginLegalLinks(),
        ],
      ),
    );
  }
}

class _LoginTopBar extends StatelessWidget {
  const _LoginTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SkinCircleButton(
          key: const Key('login-back'),
          tooltip: 'Kembali',
          icon: Icons.arrow_back_ios_new_rounded,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const Spacer(),
        const SkinBrandMark(size: 30),
        const SizedBox(width: 8),
        const SkinWordmark(fontSize: 19),
      ],
    );
  }
}

class _LoginVisualHero extends StatelessWidget {
  const _LoginVisualHero({
    required this.compact,
    required this.registerMode,
  });

  final bool compact;
  final bool registerMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 132 : 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SkinTokens.radiusXl),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: SkinTokens.shadowsLifted,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: SkinTokens.sageGradient),
          ),
          // Potret di kanan, memudar ke kiri tempat teks berada.
          FractionallySizedBox(
            alignment: Alignment.centerRight,
            widthFactor: .6,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
                stops: [0, .42],
              ).createShader(bounds),
              child: const SkinPortrait(
                asset: AppAssets.scanPortrait,
                alignment: Alignment(0, -.3),
                semanticLabel: 'Potret model dengan kulit bercahaya',
              ),
            ),
          ),
          Positioned(
            left: -26,
            bottom: -14,
            width: compact ? 120 : 140,
            height: compact ? 76 : 88,
            child: const Opacity(opacity: .9, child: SkinAloe()),
          ),
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            width: compact ? 160 : 190,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkinPill(
                  label: registerMode ? 'Akun baru' : 'Selamat datang',
                  icon: Icons.spa_outlined,
                  dense: true,
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: SkinTokens.medium,
                  child: Text(
                    registerMode
                        ? 'Mulai catatan kulitmu.'
                        : 'Lanjutkan perjalananmu.',
                    key: ValueKey(registerMode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: SkinTokens.serif,
                      color: SkinTokens.ink,
                      fontSize: compact ? 24 : 28,
                      height: 1.05,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginLegalLinks extends StatelessWidget {
  const _LoginLegalLinks();

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextButton.styleFrom(
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      textStyle: Theme.of(context)
          .textTheme
          .labelLarge!
          .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
    );
    return Column(
      children: [
        const Divider(height: 18),
        const Text(
          'Dengan melanjutkan, kamu dapat membaca ketentuan berikut.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SkinTokens.muted,
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 2,
          children: [
            TextButton(
              key: const Key('login-open-privacy'),
              style: linkStyle,
              onPressed: () => Navigator.of(context).pushNamed('/privacy'),
              child: const Text('Kebijakan Privasi'),
            ),
            TextButton(
              key: const Key('login-open-terms'),
              style: linkStyle,
              onPressed: () => Navigator.of(context).pushNamed('/terms'),
              child: const Text('Syarat & Ketentuan'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffix,
    this.onSubmitted,
    this.validator,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return TextFormField(
      key: fieldKey,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: const TextStyle(
        color: SkinTokens.ink,
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: SkinTokens.muted, size: 21),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: .8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: SkinTokens.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: SkinTokens.coral),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: SkinTokens.coral, width: 1.4),
        ),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: const Key('login-submit'),
      onPressed: onTap,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy) ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool busy;

  const _GoogleButton({required this.onTap, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: const Key('login-google'),
      onPressed: busy ? null : onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: busy
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 11),
                  Text(
                    'Menghubungkan ke Google...',
                    style:
                        TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                  ),
                ],
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SkinGoogleMark(),
                  SizedBox(width: 12),
                  Text(
                    'Masuk dengan Google',
                    style:
                        TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'atau dengan email',
            style: TextStyle(
              color: SkinTokens.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
