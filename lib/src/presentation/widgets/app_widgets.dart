import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../domain/models.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 40.0 : 52.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.35, -0.45),
              radius: 0.95,
              colors: [
                Color(0xFF24384E),
                OceanColors.obsidian,
              ],
            ),
            border: Border.all(
              color: OceanColors.champagne.withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: OceanColors.coral.withValues(alpha: 0.18),
                blurRadius: compact ? 18 : 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.anchor_rounded,
                color: OceanColors.champagne,
                size: compact ? 24 : 32,
              ),
              Positioned(
                bottom: compact ? 7 : 9,
                child: Icon(
                  Icons.favorite_rounded,
                  color: OceanColors.coral,
                  size: compact ? 8 : 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Ocean Match',
          style: OceanTypography.brand(context, compact: compact),
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
            Color(0xFF0E1B28),
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
                            Text(
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
            Color(0xFF304860),
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
              'Votre position exacte de bateau n est jamais affichee. Ocean Match utilise seulement des zones larges.',
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
