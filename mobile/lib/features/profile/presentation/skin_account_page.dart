import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import'../models/profile_data.dart';
import'../../../core/theme/skin_theme.dart';
import'../../../shared/widgets/asset_images.dart';
import'../../../shared/widgets/skin_page_background.dart';
import'../../../shared/widgets/skin_page_header.dart';
import'../../../shared/widgets/design_system/skin_ui.dart';

/// Halaman "Profil Saya": semua informasi akun dalam satu tempat — data
/// pribadi (nama, telepon, email) dan keamanan (password). Setiap baris bisa
/// diketuk untuk mengubah nilainya.
class SkinAccountPage extends StatelessWidget {
  const SkinAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkinTokens.background,
      body: SkinPageBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
              child: LayoutBuilder(builder: (context, constraints) {
                final compact = constraints.maxWidth < 350;
                final inset = compact ? 16.0 : 20.0;
                return Column(
                  children: [
                    const SkinPageHeader(
                      title: 'Profil Saya',
                      subtitle: 'Informasi akun SkinSight',
                      backKey: Key('account-back'),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const Key('account-scroll'),
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(inset, 4, inset, 28),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SkinReveal(child: _AccountSummary()),
                            SizedBox(height: 22),
                            SkinReveal(
                              delay: Duration(milliseconds: 80),
                              child: _PersonalDataCard(),
                            ),
                            SizedBox(height: 20),
                            SkinReveal(
                              delay: Duration(milliseconds: 140),
                              child: _SecurityCard(),
                            ),
                            SizedBox(height: 18),
                            SkinNotice(
                              dense: true,
                              tone: SkinTone.neutral,
                              icon: Icons.lock_outline_rounded,
                              message:
                                  'Data akunmu hanya dipakai untuk menyimpan '
                                  'riwayat dan perjalanan kulitmu.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ringkasan di atas: avatar, nama, dan email.
class _AccountSummary extends StatelessWidget {
  const _AccountSummary();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileData>();
    const size = 64.0;
    return SkinCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      radius: SkinTokens.radiusXl,
      child: Row(
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: SkinTokens.shadows,
            ),
            child: ClipOval(
              child: ColoredBox(
                color: SkinTokens.aqua,
                child: profile.photoBytes == null
                    ? Center(
                        child: Text(
                          _initials(profile.name),
                          style: const TextStyle(
                            color: SkinTokens.primaryDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : Image.memory(
                        profile.photoBytes!,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        cacheWidth: thumbnailCacheWidth(context, size),
                        gaplessPlayback: true,
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
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: SkinTokens.serif,
                    color: SkinTokens.ink,
                    fontSize: 24,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkinTokens.caption,
                ),
                const SizedBox(height: 8),
                const SkinPill(
                  label: 'Akun SkinSight',
                  icon: Icons.verified_rounded,
                  dense: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalDataCard extends StatelessWidget {
  const _PersonalDataCard();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileData>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GroupLabel('Data pribadi'),
        SkinCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ProfileField(
                editKey: const Key('edit-profile-name'),
                icon: Icons.person_outline_rounded,
                label: 'Nama',
                value: profile.name,
                onEdit: () => _editValue(
                  context,
                  title: 'Ubah nama',
                  label: 'Nama lengkap',
                  icon: Icons.person_outline_rounded,
                  initialValue: profile.name,
                  onSaved: context.read<ProfileData>().updateName,
                ),
              ),
              const _FieldDivider(),
              _ProfileField(
                editKey: const Key('edit-profile-phone'),
                icon: Icons.phone_outlined,
                label: 'Nomor telepon',
                value: profile.phone,
                onEdit: () => _editValue(
                  context,
                  title: 'Ubah nomor telepon',
                  label: 'Nomor telepon',
                  icon: Icons.phone_outlined,
                  initialValue: profile.phone,
                  keyboardType: TextInputType.phone,
                  onSaved: context.read<ProfileData>().updatePhone,
                ),
              ),
              const _FieldDivider(),
              _ProfileField(
                editKey: const Key('edit-profile-email'),
                icon: Icons.mail_outline_rounded,
                label: 'Alamat email',
                value: profile.email,
                onEdit: () => _editValue(
                  context,
                  title: 'Ubah alamat email',
                  label: 'Alamat email',
                  icon: Icons.mail_outline_rounded,
                  initialValue: profile.email,
                  keyboardType: TextInputType.emailAddress,
                  onSaved: context.read<ProfileData>().updateEmail,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GroupLabel('Keamanan'),
        SkinCard(
          padding: EdgeInsets.zero,
          child: _ProfileField(
            editKey: const Key('edit-profile-password'),
            icon: Icons.lock_outline_rounded,
            label: 'Password',
            value: '••••••••••••',
            onEdit: () => _editPassword(context),
          ),
        ),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: SkinTokens.eyebrow.copyWith(color: SkinTokens.muted),
      ),
    );
  }
}

/// Satu baris data: seluruh baris bisa diketuk, ikon edit di kanan.
class _ProfileField extends StatelessWidget {
  final Key editKey;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _ProfileField({
    required this.editKey,
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              SkinIconTile(icon: icon, size: 40),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: SkinTokens.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SkinTokens.ink,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: editKey,
                tooltip: 'Edit $label',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: SkinTokens.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 67, endIndent: 16);
}

Future<void> _editValue(
  BuildContext context, {
  required String title,
  required String label,
  required IconData icon,
  required String initialValue,
  required ValueChanged<String> onSaved,
  TextInputType? keyboardType,
}) async {
  final value = await showDialog<String>(
    context: context,
    builder: (_) => _EditValueDialog(
      title: title,
      label: label,
      icon: icon,
      initialValue: initialValue,
      keyboardType: keyboardType,
    ),
  );
  if (value != null) onSaved(value);
}

Future<void> _editPassword(BuildContext context) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => const _PasswordDialog(),
  );

  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password berhasil diperbarui.')),
    );
  }
}

class _EditValueDialog extends StatefulWidget {
  final String title;
  final String label;
  final IconData icon;
  final String initialValue;
  final TextInputType? keyboardType;

  const _EditValueDialog({
    required this.title,
    required this.label,
    required this.icon,
    required this.initialValue,
    required this.keyboardType,
  });

  @override
  State<_EditValueDialog> createState() => _EditValueDialogState();
}

class _EditValueDialogState extends State<_EditValueDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: SkinIconTile(icon: widget.icon, size: 48),
      title: Text(widget.title),
      content: TextField(
        key: const Key('profile-edit-input'),
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.keyboardType == TextInputType.emailAddress
            ? TextCapitalization.none
            : TextCapitalization.words,
        decoration: InputDecoration(labelText: widget.label),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('save-profile-edit'),
          style: FilledButton.styleFrom(minimumSize: const Size(96, 46)),
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) Navigator.of(context).pop(text);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _save() {
    if (_newPassword.text.length < 8) {
      setState(() => _error = 'Minimal 8 karakter.');
    } else if (_newPassword.text != _confirmation.text) {
      setState(() => _error = 'Password tidak sama.');
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const SkinIconTile(icon: Icons.lock_outline_rounded, size: 48),
      title: const Text('Ubah password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('new-password-input'),
            controller: _newPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password baru'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('confirm-password-input'),
            controller: _confirmation,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Ulangi password',
              errorText: _error,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('save-password'),
          style: FilledButton.styleFrom(minimumSize: const Size(96, 46)),
          onPressed: _save,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}


String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}
