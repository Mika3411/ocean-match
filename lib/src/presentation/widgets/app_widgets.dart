import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../domain/models.dart';

const bwmCompassMarkAsset = 'assets/images/bwm-compass-mark.png';
const bwmLogoFinalAsset = 'assets/images/bwm-logo-final.png';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 40.0 : 52.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PremiumLogoMark(size: markSize),
        const SizedBox(width: 12),
        GoldText(
          'BlueWater Match',
          style: OceanTypography.brand(context, compact: compact),
        ),
      ],
    );
  }
}

class PremiumLogoMark extends StatelessWidget {
  const PremiumLogoMark({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        bwmCompassMarkAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: OceanColors.copper, width: 1.6),
            ),
            child: const Icon(
              Icons.explore_outlined,
              color: OceanColors.copper,
            ),
          );
        },
      ),
    );
  }
}

class GoldText extends StatelessWidget {
  const GoldText(
    this.text, {
    required this.style,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textAlign,
    this.semanticsLabel,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextAlign? textAlign;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle =
        style ?? Theme.of(context).textTheme.titleLarge ?? const TextStyle();
    final fontSize = resolvedStyle.fontSize ?? 32;
    final strokeWidth = (fontSize * 0.032).clamp(1.0, 2.6).toDouble();
    final strokeStyle = resolvedStyle.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF6D3506),
      shadows: OceanTypography.goldTitleShadows,
    );
    final fillStyle = resolvedStyle.copyWith(
      color: Colors.white,
      shadows: const [
        Shadow(
          color: Color(0x99FFFFFF),
          offset: Offset(-0.5, -0.7),
          blurRadius: 0.8,
        ),
      ],
    );

    Widget textWithStyle(TextStyle textStyle) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: overflow,
        semanticsLabel: semanticsLabel,
        softWrap: softWrap,
        style: textStyle,
        textAlign: textAlign,
      );
    }

    Widget strokeText() {
      return RichText(
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.clip,
        softWrap: softWrap ?? true,
        text: TextSpan(text: text, style: strokeStyle),
        textAlign: textAlign ?? TextAlign.start,
        textDirection: Directionality.of(context),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ExcludeSemantics(child: strokeText()),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return OceanTypography.goldGradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            );
          },
          child: textWithStyle(fillStyle),
        ),
      ],
    );
  }
}

class OceanBackground extends StatelessWidget {
  const OceanBackground({
    required this.child,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OceanColors.abyss,
            OceanColors.midnight,
            OceanColors.deep,
          ],
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OceanColors.glassStrong,
            OceanColors.deepBlue.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OceanColors.glassLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null || trailing != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GoldText(
                              title!,
                              style: OceanTypography.sectionLabel(context),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: OceanColors.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (trailing != null) trailing!,
                  ],
                ),
              if (title != null || trailing != null) const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: OceanColors.muted,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: OceanColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class OceanBadge extends StatelessWidget {
  const OceanBadge({
    required this.label,
    this.icon,
    this.color = OceanColors.blush,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.16),
            OceanColors.obsidian.withValues(alpha: 0.44),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Color.alphaBlend(
                    color.withValues(alpha: 0.82),
                    OceanColors.sand,
                  ),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class PhotoTile extends StatelessWidget {
  const PhotoTile({
    required this.url,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String url;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (url.startsWith('http')) {
      image = Image.network(
        url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const _PhotoFallback(),
      );
    } else {
      image = Image.file(
        File(url),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const _PhotoFallback(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        color: OceanColors.mist,
        child: image,
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OceanColors.harborBlue,
            OceanColors.deepBlue,
            OceanColors.obsidian,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.anchor_rounded,
          color: OceanColors.champagne,
          size: 72,
        ),
      ),
    );
  }
}

class PrivacyNote extends StatelessWidget {
  const PrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: OceanColors.seaTeal),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Votre position exacte de bateau n est jamais affichee. BlueWater Match utilise seulement des zones larges.',
            ),
          ),
        ],
      ),
    );
  }
}

String intentionsLabel(List<Intention> intentions) {
  return intentions.map((intention) => intention.label).join(', ');
}
