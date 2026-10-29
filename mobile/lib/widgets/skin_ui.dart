import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/skin_theme.dart';
import '../core/app_assets.dart';
import 'asset_images.dart';
import 'skin_3d.dart';
import 'botanical/editorial_backdrop.dart';

/// Komponen UI bersama SkinSight. Semua halaman memakai komponen ini agar
/// kartu kaca, kapsul status, dan keadaan kosong terlihat konsisten.

// ───────────────────────── Nada warna ─────────────────────────

enum SkinTone {
  primary,
  success,
  warning,
  danger,
  info,
  neutral,
  lavender,
  peach
}

extension SkinToneColors on SkinTone {
  Color get foreground => switch (this) {
        SkinTone.primary => SkinTokens.ink,
        SkinTone.success => SkinTokens.success,
        SkinTone.warning => SkinTokens.amber,
        SkinTone.danger => SkinTokens.coral,
        SkinTone.info => SkinTokens.blue,
        SkinTone.neutral => SkinTokens.muted,
        SkinTone.lavender => SkinTokens.lavender,
        SkinTone.peach => const Color(0xFFA35E43),
      };

  Color get background => switch (this) {
        SkinTone.primary => SkinTokens.aqua,
        SkinTone.success => SkinTokens.successSoft,
        SkinTone.warning => SkinTokens.amberSoft,
        SkinTone.danger => SkinTokens.coralSoft,
        SkinTone.info => SkinTokens.blueSoft,
        SkinTone.neutral => SkinTokens.glassStrong,
        SkinTone.lavender => SkinTokens.lavenderSoft,
        SkinTone.peach => SkinTokens.peachSoft,
      };
}

// ───────────────────────── Gerak ─────────────────────────

abstract final class SkinMotion {
  /// Animasi berulang (denyut, jaring pindai) hanya berjalan di aplikasi
  /// sungguhan: tidak saat "kurangi animasi" aktif, dan tidak di widget test
  /// agar `pumpAndSettle` tetap selesai.
  static bool loops(BuildContext context) => AppMotion.loops(context);
}

/// Memunculkan child dengan fade + geser naik. Tidak memakai Timer sehingga
/// aman untuk widget test, dan langsung tampil bila "kurangi animasi" aktif.
class SkinReveal extends StatefulWidget {
  const SkinReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = SkinTokens.slow,
    this.offset = 18,
  });

  /// Helper untuk urutan bertahap pada daftar.
  SkinReveal.staggered({
    super.key,
    required this.child,
    required int index,
    this.duration = SkinTokens.slow,
    this.offset = 18,
  }) : delay = Duration(milliseconds: 60 * math.min(index, 8));

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<SkinReveal> createState() => _SkinRevealState();
}

class _SkinRevealState extends State<SkinReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    final start = total.inMicroseconds == 0
        ? 0.0
        : widget.delay.inMicroseconds / total.inMicroseconds;
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      // Struktur widget tetap sama sepanjang animasi agar state anak terjaga.
      builder: (context, child) {
        final t = _progress.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: child,
          ),
        );
      },
    );
  }
}

// ───────────────────────── Kaca ─────────────────────────

/// Permukaan kaca buram: putih transparan, blur latar, garis tepi putih
/// tipis, dan bayangan berlapis yang halus.
class SkinGlass extends StatelessWidget {
  const SkinGlass({
    super.key,
    required this.child,
    this.padding,
    this.radius = SkinTokens.radiusLg,
    this.borderRadius,
    this.color = SkinTokens.glass,
    this.gradient,
    this.borderColor = SkinTokens.glassBorder,
    this.borderWidth = 1,
    this.blur = SkinTokens.glassBlur,
    this.shadow = true,
    this.shadows,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final BorderRadius? borderRadius;
  final Color color;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;

  /// Kekuatan blur gaya CSS (px). 0 mematikan blur.
  ///
  /// Blur latar (`BackdropFilter`) adalah efek termahal di aplikasi ini:
  /// setiap permukaan memaksa GPU mengaburkan ulang isi layar di belakangnya
  /// pada SETIAP frame (scroll, transisi, animasi). Pakai hanya bila ada
  /// detail yang lewat di belakangnya (foto, konten yang tergulir di bawah
  /// bilah melayang). Di atas latar gradien halaman hasilnya tak terbedakan
  /// dari tanpa blur, jadi beri 0.
  final double blur;
  final bool shadow;
  final List<BoxShadow>? shadows;

  /// Isi seburam ini sudah hampir menutup latar; blur tidak lagi terlihat.
  static const _opaqueEnough = .85;

  @override
  Widget build(BuildContext context) {
    final shape = borderRadius ?? BorderRadius.circular(radius);
    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: shape,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    final translucent = gradient == null && color.a < _opaqueEnough;
    if (blur > 0 && translucent) {
      content = ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur / 2, sigmaY: blur / 2),
          child: content,
        ),
      );
    }
    if (!shadow) return content;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: shadows ?? SkinTokens.shadows,
      ),
      child: content,
    );
  }
}

// ───────────────────────── Kartu ─────────────────────────

class SkinCard extends StatelessWidget {
  const SkinCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = SkinTokens.glass,
    this.gradient,
    this.radius = SkinTokens.radiusLg,
    this.borderColor = SkinTokens.glassBorder,
    this.shadow = true,
    this.onTap,
    this.inkKey,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Gradient? gradient;
  final double radius;
  final Color? borderColor;
  final bool shadow;
  final VoidCallback? onTap;

  /// Key untuk InkWell bila kartu dapat diketuk.
  final Key? inkKey;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    // Garis tepi lama berwarna netral diganti tepi kaca putih.
    final edge =
        borderColor == SkinTokens.border ? SkinTokens.glassBorder : borderColor;
    final inner = onTap == null
        ? Padding(padding: padding, child: child)
        : Material(
            type: MaterialType.transparency,
            borderRadius: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: inkKey,
              onTap: onTap,
              borderRadius: shape,
              child: Padding(padding: padding, child: child),
            ),
          );
    return SkinGlass(
      radius: radius,
      color: color,
      gradient: gradient,
      borderColor: edge,
      shadow: shadow,
      // Kartu berada di alur halaman, di atas latar gradien statis.
      blur: 0,
      child: inner,
    );
  }
}

/// Lencana ikon bulat dengan latar aqua-sage lembut.
class SkinIconTile extends StatelessWidget {
  const SkinIconTile({
    super.key,
    required this.icon,
    this.tone = SkinTone.primary,
    this.size = 44,
    this.iconSize,
    this.radius,
    this.filled = false,
  });

  final IconData icon;
  final SkinTone tone;
  final double size;
  final double? iconSize;

  /// Dipertahankan untuk kompatibilitas; lencana kini selalu bulat penuh
  /// mengikuti gaya kapsul/lingkaran.
  final double? radius;

  /// Bila true: lingkaran gelap dengan ikon putih.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? SkinTokens.primary : tone.background,
        shape: BoxShape.circle,
        border: filled
            ? null
            : Border.all(color: Colors.white.withValues(alpha: .7)),
      ),
      child: Icon(
        icon,
        size: iconSize ?? size * .46,
        color: filled ? Colors.white : tone.foreground,
      ),
    );
  }
}

/// Kapsul kecil untuk status, kategori, atau metadata.
class SkinPill extends StatelessWidget {
  const SkinPill({
    super.key,
    required this.label,
    this.tone = SkinTone.primary,
    this.icon,
    this.dense = false,
  });

  final String label;
  final SkinTone tone;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final glassy = tone == SkinTone.primary || tone == SkinTone.neutral;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 9 : 12,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: glassy ? SkinTokens.glassStrong : tone.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: tone.foreground),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tone.foreground,
                fontSize: dense ? 10.5 : 12,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Judul seksi dengan subjudul opsional dan aksi di kanan.
class SkinSectionTitle extends StatelessWidget {
  const SkinSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.eyebrow,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final singleLine = subtitle == null && eyebrow == null;
    return Row(
      crossAxisAlignment:
          singleLine ? CrossAxisAlignment.center : CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(eyebrow!, style: SkinTokens.eyebrow),
                const SizedBox(height: 6),
              ],
              Text(title, style: SkinTokens.section),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: SkinTokens.caption),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing!,
        ],
      ],
    );
  }
}

/// Tautan kecil "Lihat semua" di kanan judul seksi.
class SkinSeeAll extends StatelessWidget {
  const SkinSeeAll(
      {super.key, required this.onTap, this.label = 'Lihat semua'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: SkinTokens.muted,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(44, 36),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Keadaan kosong yang menjelaskan langkah berikutnya.
class SkinEmptyState extends StatelessWidget {
  const SkinEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.spa_outlined,
    this.image,
    this.action,
    this.tone = SkinTone.primary,
    this.compact = false,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? image;
  final Widget? action;
  final SkinTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visualSize = compact ? 64.0 : 84.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (image != null)
          Skin3D(
            image!,
            width: compact ? 120 : 150,
            height: compact ? 100 : 124,
            float: true,
            floatDistance: 4,
          )
        else
          Container(
            width: visualSize,
            height: visualSize,
            decoration: BoxDecoration(
              color: tone.background,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, size: visualSize * .42, color: tone.foreground),
          ),
        SizedBox(height: compact ? 12 : 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: SkinTokens.section.copyWith(fontSize: compact ? 16.5 : 18),
        ),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(message!,
              textAlign: TextAlign.center, style: SkinTokens.caption),
        ],
        if (action != null) ...[
          const SizedBox(height: 16),
          action!,
        ],
      ],
    );
  }
}

/// Kartu catatan untuk info, peringatan, atau penafian.
class SkinNotice extends StatelessWidget {
  const SkinNotice({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.info_outline_rounded,
    this.tone = SkinTone.primary,
    this.dense = false,
  });

  final String message;
  final String? title;
  final IconData icon;
  final SkinTone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final glassy = tone == SkinTone.primary || tone == SkinTone.neutral;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dense ? 12 : 16),
      decoration: BoxDecoration(
        color:
            glassy ? SkinTokens.glass : tone.background.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(dense ? 18 : 22),
        border: Border.all(color: SkinTokens.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: dense ? 26 : 30,
            height: dense ? 26 : 30,
            decoration: BoxDecoration(
              color: glassy ? SkinTokens.aqua : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: dense ? 14 : 16, color: tone.foreground),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: TextStyle(
                        color: tone.foreground,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      color: title == null && !glassy
                          ? tone.foreground
                          : SkinTokens.ink,
                      fontSize: dense ? 12 : 12.8,
                      height: 1.5,
                      fontWeight:
                          title == null ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Tombol ─────────────────────────

/// Tombol CTA utama berbentuk kapsul gelap (atau putih bila [light]).
/// Nama lama dipertahankan agar pemanggil tidak perlu berubah.
class SkinGradientButton extends StatelessWidget {
  const SkinGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.height = 56,
    this.gradient = SkinTokens.brandGradient,
    this.foreground = Colors.white,
    this.textStyle,
    this.busy = false,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final Gradient gradient;
  final Color foreground;
  final TextStyle? textStyle;
  final bool busy;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    final enabled = onPressed != null && !busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: SkinTokens.fast,
        opacity: enabled || busy ? 1 : .45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: radius,
            boxShadow: enabled
                ? SkinTokens.glow(SkinTokens.primary, opacity: .22)
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: radius,
              child: SizedBox(
                height: height,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    leading == null ? 24 : 8,
                    0,
                    icon == null ? 24 : 8,
                    0,
                  ),
                  child: Row(
                    children: [
                      if (leading != null && !busy) ...[
                        leading!,
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: busy
                            ? Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: foreground,
                                  ),
                                ),
                              )
                            : Text(
                                label,
                                maxLines: 1,
                                textAlign: leading != null
                                    ? TextAlign.start
                                    : TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: (textStyle ??
                                        const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ))
                                    .copyWith(color: foreground),
                              ),
                      ),
                      if (icon != null && !busy) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: height - 16,
                          height: height - 16,
                          decoration: BoxDecoration(
                            color: foreground.withValues(alpha: .14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 18, color: foreground),
                        ),
                      ],
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

/// Tombol ikon bulat 44px berlatar kaca.
class SkinCircleButton extends StatelessWidget {
  const SkinCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.iconColor = SkinTokens.ink,
    this.background = SkinTokens.glassStrong,
    this.shadow = true,
    this.badge = false,
    this.badgeKey,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color iconColor;
  final Color background;
  final bool shadow;
  final bool badge;
  final Key? badgeKey;

  @override
  Widget build(BuildContext context) {
    // Warna lama "putih penuh" dibaca sebagai permintaan kaca.
    final fill =
        background == SkinTokens.surface ? SkinTokens.glassStrong : background;
    Widget button = SkinGlass(
      radius: size / 2,
      color: fill,
      borderColor: SkinTokens.surface.withValues(alpha: .85),
      shadow: shadow,
      // Tombol kecil & hampir buram: blur tidak terlihat, tapi tetap mahal.
      blur: 0,
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              color: iconColor == SkinTokens.primaryDark
                  ? SkinTokens.ink
                  : iconColor,
              size: size * .45,
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    if (!badge) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: size * .18,
          right: size * .2,
          child: IgnorePointer(
            child: Container(
              key: badgeKey,
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: SkinTokens.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tombol menu kisi melingkar (titik 3×3) seperti di dasbor referensi.
class SkinGridMenuButton extends StatelessWidget {
  const SkinGridMenuButton({super.key, required this.onPressed, this.tooltip});

  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SkinCircleButton(
      icon: Icons.apps_rounded,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

/// Bilah aksi bawah berbahan kaca dengan sudut atas membulat.
class SkinBottomBar extends StatelessWidget {
  const SkinBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SkinGlass(
      borderRadius: const BorderRadius.vertical(
          top: Radius.circular(SkinTokens.radiusXl)),
      color: SkinTokens.glassStrong,
      borderColor: SkinTokens.surface,
      shadows: const [
        BoxShadow(
          color: Color(0x141F2A27),
          blurRadius: 30,
          offset: Offset(0, -8),
        ),
      ],
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 14, 24, 16),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: SkinTokens.maxWidth - 48),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Chip filter ─────────────────────────

/// Deret chip kapsul yang dapat digeser horizontal. Aktif = putih,
/// tidak aktif = kaca transparan.
class SkinFilterChipBar extends StatelessWidget {
  const SkinFilterChipBar({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
    this.keyPrefix,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        clipBehavior: Clip.none,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => SkinFilterChip(
          key: keyPrefix == null ? null : Key('$keyPrefix-$index'),
          label: labels[index],
          selected: index == selected,
          onTap: () => onSelected(index),
        ),
      ),
    );
  }
}

class SkinFilterChip extends StatelessWidget {
  const SkinFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: SkinTokens.medium,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? Colors.white : SkinTokens.glassSoft,
          borderRadius: radius,
          border: Border.all(
            color: selected ? Colors.white : SkinTokens.glassBorder,
          ),
          boxShadow: selected ? SkinTokens.shadows : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon,
                        size: 15,
                        color: selected ? SkinTokens.ink : SkinTokens.muted),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? SkinTokens.ink : SkinTokens.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Data visual ─────────────────────────

/// Kapsul statistik: gelap (kontras tinggi) atau terang/kaca.
/// Dipakai untuk angka penting seperti "Kesehatan kulit 75%".
class SkinStatCapsule extends StatelessWidget {
  const SkinStatCapsule({
    super.key,
    required this.label,
    required this.value,
    this.dark = false,
    this.icon,
  });

  final String label;
  final String value;
  final bool dark;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : SkinTokens.ink;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: dark ? SkinTokens.primary : Colors.white.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(22),
        border: dark ? null : Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg.withValues(alpha: .7)),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    color: dark
                        ? Colors.white.withValues(alpha: .7)
                        : SkinTokens.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris metrik kapsul semi-transparan: label kiri, nilai kanan. Lebarnya
/// mengikuti [fraction] sehingga kapsul sekaligus berfungsi sebagai bar.
class SkinMetricPill extends StatelessWidget {
  const SkinMetricPill({
    super.key,
    required this.label,
    required this.value,
    this.fraction,
    this.icon,
  });

  final String label;
  final String value;

  /// 0–1; null = lebar penuh.
  final double? fraction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final max = constraints.maxWidth;
      final min = math.min(max, 170.0);
      final f = fraction?.clamp(0.0, 1.0);
      final width = f == null ? max : min + (max - min) * f;
      return Align(
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: min, end: width),
          duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
              ? Duration.zero
              : const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, w, child) => SizedBox(width: w, child: child),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: SkinTokens.muted),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: SkinTokens.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SkinTokens.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Bilah progres membulat dengan animasi perubahan nilai.
class SkinProgressBar extends StatelessWidget {
  const SkinProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color = SkinTokens.primary,
    this.background = SkinTokens.aqua,
    this.gradient,
  });

  final double value;
  final double height;
  final Color color;
  final Color background;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        height: height,
        decoration: BoxDecoration(
          color: background == SkinTokens.mint ? SkinTokens.aqua : background,
          borderRadius: BorderRadius.circular(height),
        ),
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: SkinTokens.slow,
          curve: Curves.easeOutCubic,
          width: constraints.maxWidth * clamped,
          height: height,
          decoration: BoxDecoration(
            color: gradient == null ? color : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      ),
    );
  }
}

/// Cincin progres melingkar.
class SkinRing extends StatelessWidget {
  const SkinRing({
    super.key,
    required this.value,
    this.size = 58,
    this.stroke = 6,
    this.color = SkinTokens.aquaDeep,
    this.track = SkinTokens.aqua,
    this.child,
  });

  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Color track;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
            ? Duration.zero
            : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, animated, child) => CustomPaint(
          painter: _RingPainter(
            animated,
            stroke,
            color == SkinTokens.primary ? SkinTokens.aquaDeep : color,
            track == SkinTokens.mint || track == Colors.white
                ? SkinTokens.aqua.withValues(alpha: .55)
                : track,
          ),
          child: child,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.value, this.stroke, this.color, this.track);

  final double value;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      base
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Pegangan tarik untuk panel bawah.
class SkinDragHandle extends StatelessWidget {
  const SkinDragHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: SkinTokens.ink.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
}

// ───────────────────────── Dekorasi alam & foto ─────────────────────────

/// Rumpun lidah buaya 3D (render). Parameter lama dipertahankan agar
/// pemanggil tidak perlu berubah; warna & jumlah daun kini dari aset.
class SkinAloe extends StatelessWidget {
  const SkinAloe({super.key, this.color = SkinTokens.aloe, this.leaves = 5});

  final Color color;
  final int leaves;

  @override
  Widget build(BuildContext context) => Image.asset(
        AppAssets.aloe3d,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        cacheWidth: 360,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
}

/// Foto potret dari aset yang boleh belum ada di repo.
///
/// Keberadaan file dicek lewat AssetManifest (tanpa request bila tidak ada,
/// jadi tidak ada 404). Bila belum tersedia, tampil [EditorialBackdrop]:
/// mesh gradient sage–aqua–krem dengan rumpun lidah buaya, bukan siluet.
class SkinPortrait extends StatelessWidget {
  const SkinPortrait({
    super.key,
    required this.asset,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.profile = false,
  });

  final String asset;
  final Alignment alignment;
  final String? semanticLabel;

  /// Variasi komposisi fallback (dicerminkan) untuk ilustrasi pemindaian.
  final bool profile;

  @override
  Widget build(BuildContext context) {
    return OptionalAssetImage(
      asset: asset,
      alignment: alignment,
      semanticLabel: semanticLabel,
      fallback: EditorialBackdrop(
        mirror: profile,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// Lapisan jaring pemindai bercahaya: garis tipis putih dengan titik simpul
/// yang berdenyut, menutupi area rahang & leher.
class SkinScanMesh extends StatefulWidget {
  const SkinScanMesh({
    super.key,
    this.region = const Rect.fromLTWH(.36, .34, .4, .5),
  });

  /// Area jaring dalam koordinat ternormalisasi (0–1) dari ukuran widget.
  final Rect region;

  @override
  State<SkinScanMesh> createState() => _SkinScanMeshState();
}

class _SkinScanMeshState extends State<SkinScanMesh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SkinMotion.loops(context)) {
      // Berdenyut beberapa siklus lalu diam; jaring tetap terlihat.
      if (!_controller.isAnimating && _controller.isDismissed) {
        _controller.repeat(count: AppMotion.ambientCycles);
      }
    } else {
      _controller.value = .25;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Garis jaring statis di lapisan sendiri; hanya titik simpul yang
    // dilukis ulang setiap frame denyut.
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(painter: _MeshLinesPainter(widget.region)),
          ),
          RepaintBoundary(
            child: CustomPaint(
              painter: _MeshNodesPainter(_controller, widget.region),
            ),
          ),
        ],
      ),
    );
  }
}

/// Geometri jaring bersama untuk lapisan garis & titik simpul.
mixin _MeshGeometry {
  Rect get region;

  static const cols = 6;
  static const rows = 7;

  Offset point(Size size, int c, int r) {
    final u = c / (cols - 1);
    final v = r / (rows - 1);
    // Lengkung mengikuti kontur rahang → leher.
    final bend = math.sin(v * math.pi) * .12;
    final x = region.left + region.width * (u + (u - .5) * bend);
    final y = region.top +
        region.height * v +
        math.sin(u * math.pi) * region.height * .05 * (1 - v);
    return Offset(x * size.width, y * size.height);
  }

  /// Ukuran garis & titik mengikuti ukuran kanvas: tetap ringan di thumbnail.
  double scaleFor(Size size) =>
      (math.min(size.width, size.height) / 360).clamp(.35, 1.2);
}

class _MeshLinesPainter extends CustomPainter with _MeshGeometry {
  const _MeshLinesPainter(this.region);

  @override
  final Rect region;

  @override
  void paint(Canvas canvas, Size size) {
    const cols = _MeshGeometry.cols;
    const rows = _MeshGeometry.rows;
    final s = scaleFor(size);
    // Semua ruas digabung ke satu path: cahaya garis cukup satu operasi
    // blur, bukan satu blur per ruas.
    final edges = Path();
    final diagonals = Path();
    void segment(Path path, Offset p, Offset q) => path
      ..moveTo(p.dx, p.dy)
      ..lineTo(q.dx, q.dy);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final p = point(size, c, r);
        if (c < cols - 1) segment(edges, p, point(size, c + 1, r));
        if (r < rows - 1) segment(edges, p, point(size, c, r + 1));
        if (c < cols - 1 && r < rows - 1 && (c + r).isEven) {
          segment(diagonals, p, point(size, c + 1, r + 1));
        }
      }
    }
    final stroke = Paint()..style = PaintingStyle.stroke;
    canvas
      ..drawPath(
        edges,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: .35)
          ..strokeWidth = 3 * s
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * s),
      )
      ..drawPath(
        edges,
        stroke
          ..color = Colors.white.withValues(alpha: .75)
          ..strokeWidth = math.max(.5, .9 * s),
      )
      ..drawPath(
        diagonals,
        stroke..color = Colors.white.withValues(alpha: .4),
      );
  }

  @override
  bool shouldRepaint(covariant _MeshLinesPainter old) => old.region != region;
}

class _MeshNodesPainter extends CustomPainter with _MeshGeometry {
  _MeshNodesPainter(this.progress, this.region) : super(repaint: progress);

  final Animation<double> progress;

  @override
  final Rect region;

  @override
  void paint(Canvas canvas, Size size) {
    const cols = _MeshGeometry.cols;
    const rows = _MeshGeometry.rows;
    final s = scaleFor(size);
    final t = progress.value;
    // Titik simpul berkilau yang berdenyut bergiliran.
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final phase = ((c * 3 + r * 5) % 11) / 11;
        final pulse = .5 + .5 * math.sin((t + phase) * math.pi * 2);
        final p = point(size, c, r);
        canvas.drawCircle(
          p,
          (3 + pulse * 5) * s,
          Paint()
            ..color = Colors.white.withValues(alpha: .18 + pulse * .35)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * s),
        );
        canvas.drawCircle(
            p, (1.4 + pulse * 1.1) * s, Paint()..color = Colors.white);
        if ((c + r) % 4 == 0) {
          _sparkle(canvas, p, (4 + pulse * 4) * s, pulse);
        }
      }
    }
  }

  void _sparkle(Canvas canvas, Offset c, double r, double alpha) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .5 + alpha * .5);
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MeshNodesPainter old) =>
      old.progress != progress || old.region != region;
}

// ───────────────────────── Brand ─────────────────────────

/// Logo SkinSight: lingkaran lensa dengan titik-titik pemindai.
class SkinBrandMark extends StatelessWidget {
  const SkinBrandMark({
    super.key,
    this.size = 38,
    this.onBrand = false,
  });

  final double size;

  /// Bila true: digambar putih untuk di atas latar gelap.
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .14),
      decoration: BoxDecoration(
        color:
            onBrand ? Colors.white.withValues(alpha: .16) : SkinTokens.primary,
        shape: BoxShape.circle,
        border: onBrand
            ? Border.all(color: Colors.white.withValues(alpha: .4))
            : null,
      ),
      child: const CustomPaint(painter: _BrandMarkPainter()),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .075
      ..color = Colors.white;
    final fill = Paint()..color = Colors.white;
    canvas.drawCircle(center, size.width * .43, stroke);
    canvas.drawCircle(center, size.width * .11, fill..color = SkinTokens.aqua);
    fill.color = Colors.white;
    for (var index = 0; index < 8; index++) {
      final angle = (math.pi * 2 / 8) * index;
      final point = Offset(
        center.dx + math.cos(angle) * size.width * .27,
        center.dy + math.sin(angle) * size.width * .27,
      );
      canvas.drawCircle(point, size.width * .04, fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wordmark "SkinSight": sans tebal + serif miring.
class SkinWordmark extends StatelessWidget {
  const SkinWordmark({super.key, this.fontSize = 22, this.onBrand = false});

  final double fontSize;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final color = onBrand ? Colors.white : SkinTokens.ink;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Skin',
            style: TextStyle(
              fontFamily: SkinTokens.sans,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
              color: color,
            ),
          ),
          TextSpan(
            text: 'Sight',
            style: TextStyle(
              fontFamily: SkinTokens.serif,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w300,
              fontSize: fontSize * 1.18,
              color: onBrand ? Colors.white.withValues(alpha: .85) : color,
            ),
          ),
        ],
      ),
      style: TextStyle(fontSize: fontSize, height: 1.1),
    );
  }
}

/// Logo "G" Google empat warna (warna brand pihak ketiga).
class SkinGoogleMark extends StatelessWidget {
  const SkinGoogleMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: const CustomPaint(painter: _GoogleMarkPainter()),
      );
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .2;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    Paint arc(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color;
    const deg = math.pi / 180;
    canvas.drawArc(
        rect, -40 * deg, -100 * deg, false, arc(const Color(0xFFEA4335)));
    canvas.drawArc(
        rect, -140 * deg, -90 * deg, false, arc(const Color(0xFFFBBC05)));
    canvas.drawArc(
        rect, -230 * deg, -95 * deg, false, arc(const Color(0xFF34A853)));
    canvas.drawArc(
        rect, -325 * deg, -35 * deg, false, arc(const Color(0xFF4285F4)));
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - stroke / 2,
        size.width - stroke * .05,
        center.dy + stroke / 2,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────────────── Format ─────────────────────────

abstract final class SkinFormat {
  static const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  static const shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  static const weekdays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// 22 Oktober 2026
  static String date(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year}';

  /// 22 Okt 2026
  static String shortDate(DateTime d) =>
      '${d.day} ${shortMonths[d.month - 1]} ${d.year}';

  /// 22 Okt
  static String dayMonth(DateTime d) => '${d.day} ${shortMonths[d.month - 1]}';

  /// Kamis, 22 Oktober 2026
  static String longDate(DateTime d) =>
      '${weekdays[d.weekday - 1]}, ${date(d)}';

  /// 09.30
  static String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';

  /// Sapaan sesuai waktu lokal perangkat.
  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }
}
