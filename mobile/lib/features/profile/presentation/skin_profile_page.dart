import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import'../../auth/data/auth_service.dart';
import'../../journeys/data/skin_journey_store.dart';
import'../../auth/models/auth_session.dart';
import'../models/profile_data.dart';
import'../../../core/theme/skin_theme.dart';
import'../../../shared/widgets/asset_images.dart';
import'../../../shared/widgets/navigation/skin_bottom_nav.dart';
import'../../../shared/widgets/skin_page_background.dart';
import'../../../shared/widgets/skin_page_header.dart';
import'../../../shared/widgets/design_system/skin_ui.dart';

class SkinProfilePage extends StatelessWidget {
  const SkinProfilePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 350;
            return Column(
              children: [
                if (embedded)
                  _EmbeddedProfileHeader(compact: compact)
                else
                  const SkinPageHeader(
                    title: 'Profil',
                    backKey: Key('profile-back'),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    key: const Key('profile-scroll'),
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 20,
                      6,
                      compact ? 16 : 20,
                      SkinBottomNav.overlap + 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Kartu 1: identitas pengguna + akses "Profil Saya".
                        SkinReveal(child: _IdentitySection(compact: compact)),
                        const SizedBox(height: 22),
                        // Kartu 2: tautan lainnya + keluar akun.
                        const SkinReveal(
                          delay: Duration(milliseconds: 100),
                          child: _SupportLinks(),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'SkinSight · versi 1.1.0',
                            style: TextStyle(
                              color: SkinTokens.subtle,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    if (embedded) return content;

    return Scaffold(
      backgroundColor: SkinTokens.background,
      extendBody: true,
      body: SkinPageBackground(
        child: SafeArea(bottom: false, child: content),
      ),
      bottomNavigationBar: const SkinBottomNav(currentIndex: 4),
    );
  }
}

class _EmbeddedProfileHeader extends StatelessWidget {
  final bool compact;

  const _EmbeddedProfileHeader({required this.compact});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(compact ? 16 : 20, 18, 20, 10),
        child: const Row(
          children: [
            Expanded(
              child: Text('Profil', style: SkinTokens.title),
            ),
            SkinIconTile(icon: Icons.person_outline_rounded, size: 44),
          ],
        ),
      );
}

class _IdentitySection extends StatelessWidget {
  final bool compact;

  const _IdentitySection({required this.compact});

  Future<void> _pickPhoto(BuildContext context, ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1200,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!context.mounted) return;
    context.read<ProfileData>().updatePhoto(bytes);
  }

  void _showPhotoSource(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ubah foto profil', style: SkinTokens.section),
              const SizedBox(height: 4),
              const Text(
                'Pilih sumber foto yang ingin kamu gunakan.',
                style: SkinTokens.caption,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _PhotoSourceTile(
                      key: const Key('profile-photo-camera'),
                      icon: Icons.photo_camera_outlined,
                      label: 'Ambil foto',
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _pickPhoto(context, ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PhotoSourceTile(
                      key: const Key('profile-photo-gallery'),
                      icon: Icons.photo_library_outlined,
                      label: 'Pilih dari galeri',
                      tone: SkinTone.info,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _pickPhoto(context, ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileData>();
    final initials = _initials(profile.name);
    final avatarSize = compact ? 84.0 : 96.0;

    return SkinCard(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
      radius: SkinTokens.radiusXl,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: SkinTokens.shadowsLifted,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: SkinTokens.aqua,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 3),
                    ),
                  ),
                  child: ClipOval(
                    child: profile.photoBytes == null
                        ? Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: SkinTokens.primaryDark,
                                fontSize: compact ? 28 : 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : Image.memory(
                            profile.photoBytes!,
                            key: const Key('profile-photo'),
                            fit: BoxFit.cover,
                            width: avatarSize,
                            height: avatarSize,
                            cacheWidth: thumbnailCacheWidth(context, avatarSize),
                            gaplessPlayback: true,
                          ),
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Material(
                    color: SkinTokens.ink,
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('edit-profile-photo'),
                      onTap: () => _showPhotoSource(context),
                      customBorder: const CircleBorder(),
                      child: const Tooltip(
                        message: 'Ubah foto profil',
                        child: SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(
                            Icons.photo_camera_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            profile.name,
            key: const Key('profile-name-heading'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: SkinTokens.serif,
              color: SkinTokens.ink,
              fontSize: compact ? 28 : 32,
              height: 1.1,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const SkinPill(
            label: 'Akun SkinSight',
            icon: Icons.verified_rounded,
          ),
          const SizedBox(height: 18),
          const _JourneyStats(),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          const _AccountEntry(),
        ],
      ),
    );
  }
}

class _JourneyStats extends StatelessWidget {
  const _JourneyStats();

  @override
  Widget build(BuildContext context) {
    final store = SkinJourneyStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final journeys = store.journeys;
        final photos = journeys.fold<int>(0, (sum, j) => sum + j.photos.length);
        final checkins =
            journeys.fold<int>(0, (sum, j) => sum + j.checkins.length);
        return Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Perjalanan',
                value: '${journeys.length}',
                highlight: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _StatTile(label: 'Sesi foto', value: '$photos')),
            const SizedBox(width: 8),
            Expanded(child: _StatTile(label: 'Check-in', value: '$checkins')),
          ],
        );
      },
    );
  }
}

/// Angka ringkas: nilai besar di atas, label kecil di bawah (label mengecil
/// otomatis agar tidak terpotong di layar sempit).
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final fg = highlight ? Colors.white : SkinTokens.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? SkinTokens.primary : Colors.white.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(20),
        border: highlight ? null : Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: fg,
              fontSize: 22,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: highlight
                    ? Colors.white.withValues(alpha: .78)
                    : SkinTokens.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris "Profil Saya" di dalam kartu identitas: membuka halaman detail akun
/// (nama, telepon, email, password).
class _AccountEntry extends StatelessWidget {
  const _AccountEntry();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileData>();
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const Key('open-account-details'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).pushNamed('/account'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 2, 10),
          child: Row(
            children: [
              const SkinIconTile(
                icon: Icons.badge_outlined,
                size: 42,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profil Saya',
                      style: TextStyle(
                        color: SkinTokens.ink,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SkinTokens.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const SkinPill(label: 'Ubah', dense: true),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: SkinTokens.subtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone = SkinTone.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final SkinTone tone;

  @override
  Widget build(BuildContext context) {
    return SkinCard(
      onTap: onTap,
      shadow: false,
      color: tone.background,
      borderColor: null,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tone.foreground),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SkinTokens.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 67, endIndent: 16);
  }
}

class _SupportLinks extends StatelessWidget {
  const _SupportLinks();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GroupLabel('Lainnya'),
        SkinCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SupportLink(
                key: const Key('profile-open-help'),
                icon: Icons.help_outline_rounded,
                tone: SkinTone.info,
                label: 'Bantuan',
                subtitle: 'Pusat bantuan dan pertanyaan umum',
                onTap: () => Navigator.of(context).pushNamed('/help'),
              ),
              const _FieldDivider(),
              _SupportLink(
                key: const Key('profile-open-about'),
                icon: Icons.info_outline_rounded,
                tone: SkinTone.lavender,
                label: 'Tentang Kami',
                subtitle: 'Kenali SkinSight lebih dekat',
                onTap: () => Navigator.of(context).pushNamed('/about'),
              ),
              const _FieldDivider(),
              _SupportLink(
                key: const Key('profile-open-settings'),
                icon: Icons.text_fields_rounded,
                tone: SkinTone.peach,
                label: 'Tampilan tulisan',
                subtitle: 'Pilih gaya font aplikasi',
                onTap: () => Navigator.of(context).pushNamed('/settings'),
              ),
              const _FieldDivider(),
              _SupportLink(
                key: const Key('logout-account'),
                icon: Icons.logout_rounded,
                tone: SkinTone.danger,
                label: 'Keluar akun',
                subtitle: 'Akhiri sesi di perangkat ini',
                danger: true,
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportLink extends StatelessWidget {
  final IconData icon;
  final SkinTone tone;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _SupportLink({
    super.key,
    required this.icon,
    required this.tone,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              SkinIconTile(icon: icon, tone: tone, size: 40, radius: 13),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: danger ? SkinTokens.coral : SkinTokens.ink,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: SkinTokens.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: SkinTokens.subtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const SkinIconTile(
        icon: Icons.logout_rounded,
        tone: SkinTone.danger,
        size: 48,
      ),
      title: const Text('Keluar dari akun?'),
      content: const Text(
        'Kamu perlu masuk kembali untuk membuka data akun SkinSight.',
        textAlign: TextAlign.center,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('confirm-logout'),
          style: FilledButton.styleFrom(
            backgroundColor: SkinTokens.coral,
            minimumSize: const Size(96, 46),
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Keluar'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    try {
      await context.read<AuthService>().signOut();
    } catch (_) {
      // Best effort: sesi lokal tetap diakhiri bila server tidak tersedia.
    }
    if (!context.mounted) return;
    AuthSession.instance.signOut();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    messenger.showSnackBar(
      const SnackBar(content: Text('Kamu telah keluar dari akun.')),
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
