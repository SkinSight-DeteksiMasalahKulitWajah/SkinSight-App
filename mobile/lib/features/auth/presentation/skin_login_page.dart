import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/cloud_sync.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/skin_theme.dart';
import '../../../shared/widgets/design_system/skin_ui.dart';
import '../../../shared/widgets/skin_page_background.dart';
import '../../profile/models/profile_data.dart';
import '../data/auth_service.dart';
import '../models/auth_session.dart';

class SkinLoginPage extends StatefulWidget {
  const SkinLoginPage({super.key, this.initialRegisterMode = false});

  final bool initialRegisterMode;

  @override
  State<SkinLoginPage> createState() => _SkinLoginPageState();
}

class _SkinLoginPageState extends State<SkinLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();

  bool _obscurePassword = true;
  late bool _registerMode;
  bool _submittedOnce = false;
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
    if (!_submittedOnce) {
      setState(() => _submittedOnce = true);
    }
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
        if (!mounted) return;
        // Jika pendaftaran membutuhkan konfirmasi email (currentSession masih null)
        if (!auth.isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pendaftaran berhasil! Cek email untuk konfirmasi atau silakan langsung masuk.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
          setState(() {
            _registerMode = false; // Pindahkan form ke mode Masuk
            _submittedOnce = false;
          });
          return;
        }
      } else {
        await auth.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      if (!mounted) return;
      ProfileData.current?.syncFromAuthImmediate();
      unawaited(CloudSync.instance.refresh());
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
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _googleBusy = true;
    });
    try {
      final auth = context.read<AuthService>();
      await auth.signInWithGoogle();
      if (!mounted) return;
      if (!auth.isAuthenticated) {
        return; // Dibatalkan, jangan pindah halaman.
      }
      ProfileData.current?.syncFromAuthImmediate();
      unawaited(CloudSync.instance.refresh());
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
      _submittedOnce = false;
      _formKey.currentState?.reset();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.offset <= 0) return;
      if (AppMotion.reduceMotion(context)) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.animateTo(
          0,
          duration: SkinTokens.medium,
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);

    return Scaffold(
      backgroundColor: SkinTokens.background,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SkinPageBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxWidth < 360 || constraints.maxHeight < 680;
                final horizontalPadding = compact ? 16.0 : 24.0;
                final verticalPadding = compact ? 10.0 : 16.0;
                final minBodyHeight = math.max(
                  0.0,
                  constraints.maxHeight - (verticalPadding * 2),
                );
                // Beri ruang atas untuk tombol kembali hanya pada layar pendek/sempit
                // agar di layar standar & besar blok login duduk tepat di pusat vertikal.
                final reserveTopForBack =
                    compact || (_registerMode && constraints.maxHeight < 780);

                return SingleChildScrollView(
                  key: const Key('login-scroll'),
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        minHeight: minBodyHeight,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Positioned(
                            top: 0,
                            left: 0,
                            child: _LoginTopBar(),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              top: reserveTopForBack ? 52 : 0,
                            ),
                            child: Form(
                              key: _formKey,
                              autovalidateMode: _submittedOnce
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                              child: AutofillGroup(
                                child: Column(
                                  key: const Key('login-auth-block'),
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _BrandAnchor(compact: compact),
                                    SizedBox(height: compact ? 14 : 18),
                                    _buildFormCard(
                                      compact: compact,
                                      reduceMotion: reduceMotion,
                                    ),
                                    SizedBox(height: compact ? 10 : 12),
                                    const _LoginLegalLinks(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required bool compact,
    required bool reduceMotion,
  }) {
    return Container(
      key: const Key('login-card'),
      decoration: BoxDecoration(
        color: SkinTokens.surface,
        borderRadius: BorderRadius.circular(compact ? 24 : 28),
        border: Border.all(color: SkinTokens.border),
        boxShadow: SkinTokens.shadows,
      ),
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 24,
        compact ? 20 : 24,
        compact ? 18 : 24,
        compact ? 12 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : SkinTokens.fast,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Column(
              key: ValueKey(_registerMode),
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _registerMode
                      ? 'Buat akun SkinSight'
                      : 'Selamat datang kembali',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SkinTokens.ink,
                    fontSize: compact ? 20.5 : 22,
                    height: 1.2,
                    letterSpacing: -0.45,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 245),
                  child: Text(
                    _registerMode
                        ? 'Mulai kenali kondisi kulitmu dengan akun baru.'
                        : 'Masuk untuk memulihkan riwayat & perjalanan kulitmu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SkinTokens.muted,
                      fontSize: compact ? 13 : 13.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 16 : 20),
          AnimatedSize(
            duration: reduceMotion ? Duration.zero : SkinTokens.medium,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _registerMode
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AuthField(
                      fieldKey: const Key('register-name'),
                      controller: _nameController,
                      label: 'Nama lengkap',
                      icon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Nama perlu diisi.'
                              : null,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          _AuthField(
            fieldKey: const Key('login-email'),
            controller: _emailController,
            label: 'Alamat email',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [
              AutofillHints.email,
              AutofillHints.username,
            ],
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
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: _registerMode
                ? const [AutofillHints.newPassword]
                : const [AutofillHints.password],
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
                size: 20,
              ),
            ),
            validator: (value) {
              if ((value ?? '').length < 6) {
                return 'Password minimal 6 karakter.';
              }
              return null;
            },
          ),
          AnimatedSize(
            duration: reduceMotion ? Duration.zero : SkinTokens.fast,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _registerMode
                ? const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: SkinTokens.muted,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Gunakan minimal 6 karakter.',
                            style: TextStyle(
                              color: SkinTokens.muted,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(height: compact ? 16 : 20),
          _PrimaryAuthButton(
            label: _busy
                ? 'Memproses...'
                : _registerMode
                    ? 'Daftar'
                    : 'Masuk',
            busy: _busy && !_googleBusy,
            disabled: _busy,
            onTap: _submit,
          ),
          SizedBox(height: compact ? 12 : 14),
          const _OrDivider(),
          SizedBox(height: compact ? 12 : 14),
          _GoogleButton(
            onTap: _continueWithGoogle,
            busy: _googleBusy,
            disabled: _busy,
          ),
          SizedBox(height: compact ? 8 : 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 2,
            children: [
              Text(
                _registerMode ? 'Sudah punya akun?' : 'Belum punya akun?',
                style: const TextStyle(
                  color: SkinTokens.muted,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              TextButton(
                key: const Key('login-register-toggle'),
                onPressed: _busy ? null : _toggleMode,
                style: TextButton.styleFrom(
                  foregroundColor: SkinTokens.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(44, 44),
                ),
                child: Text(
                  _registerMode ? 'Masuk' : 'Daftar',
                  style: const TextStyle(
                    color: SkinTokens.primary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginTopBar extends StatelessWidget {
  const _LoginTopBar();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SkinCircleButton(
        key: const Key('login-back'),
        tooltip: 'Kembali',
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

class _BrandAnchor extends StatelessWidget {
  const _BrandAnchor({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 48.0 : 54.0;
    final radius = compact ? 15.0 : 17.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: SkinTokens.surface,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.forestDeep.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: AppColors.glassShadow,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - 2),
            child: Image.asset(
              'assets/app_icon.png',
              width: iconSize,
              height: iconSize,
              fit: BoxFit.cover,
              semanticLabel: 'Logo SkinSight',
              errorBuilder: (_, __, ___) => SkinBrandMark(size: iconSize),
            ),
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        SkinWordmark(fontSize: compact ? 21 : 24),
      ],
    );
  }
}

class _LoginLegalLinks extends StatelessWidget {
  const _LoginLegalLinks();

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextButton.styleFrom(
      foregroundColor: SkinTokens.primary,
      minimumSize: const Size(44, 36),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Dengan melanjutkan, kamu dapat membaca ketentuan berikut.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SkinTokens.muted,
            fontSize: 11.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 2),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2,
          children: [
            TextButton(
              key: const Key('login-open-privacy'),
              style: linkStyle,
              onPressed: () => Navigator.of(context).pushNamed('/privacy'),
              child: const Text('Kebijakan Privasi'),
            ),
            const Text(
              '·',
              style: TextStyle(
                color: SkinTokens.subtle,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
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
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.autofillHints,
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
  final bool autocorrect;
  final bool enableSuggestions;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(SkinTokens.radiusSm);
    return TextFormField(
      key: fieldKey,
      controller: controller,
      obscureText: obscureText,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: const TextStyle(
        color: SkinTokens.ink,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: SkinTokens.muted,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.error)) {
            return const TextStyle(
              color: SkinTokens.coral,
              fontWeight: FontWeight.w700,
            );
          }
          if (states.contains(WidgetState.focused)) {
            return const TextStyle(
              color: SkinTokens.primary,
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(
            color: SkinTokens.muted,
            fontWeight: FontWeight.w600,
          );
        }),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: SkinTokens.muted, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.mistBottom,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: SkinTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: SkinTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: SkinTokens.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: SkinTokens.coral, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: SkinTokens.coral, width: 1.6),
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
    this.disabled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool busy;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(SkinTokens.radiusPill);
    return AnimatedOpacity(
      duration: SkinTokens.fast,
      opacity: disabled ? 0.78 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: SkinTokens.brandGradient,
          borderRadius: radius,
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: SkinTokens.primary.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: FilledButton(
          key: const Key('login-submit'),
          onPressed: disabled ? null : onTap,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: SkinTokens.surface,
            disabledForegroundColor: SkinTokens.surface,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            minimumSize: const Size.fromHeight(54),
            shape: const StadiumBorder(),
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
                    color: SkinTokens.surface,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.onTap,
    this.busy = false,
    this.disabled = false,
  });

  final VoidCallback onTap;
  final bool busy;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: const Key('login-google'),
      onPressed: disabled ? null : onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: SkinTokens.surface,
        foregroundColor: SkinTokens.ink,
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        side: BorderSide(
          color: SkinTokens.borderStrong.withValues(alpha: 0.75),
          width: 1.1,
        ),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: SkinTokens.primary,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Menghubungkan ke Google...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SkinGoogleMark(size: 19),
                  SizedBox(width: 11),
                  Text(
                    'Masuk dengan Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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
        Expanded(child: Divider(color: SkinTokens.border, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'atau',
            style: TextStyle(
              color: SkinTokens.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: SkinTokens.border, height: 1)),
      ],
    );
  }
}
