import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../domain/models.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 36 : 48,
          height: compact ? 36 : 48,
          decoration: BoxDecoration(
            color: OceanColors.cardAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: OceanColors.line),
          ),
          child: Icon(
            Icons.directions_boat_filled,
            color: OceanColors.gold,
            size: compact ? 22 : 30,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Ocean Match',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w600,
                color: OceanColors.sand,
              ),
        ),
      ],
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
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: OceanColors.gold,
                                  fontWeight: FontWeight.w800,
                                ),
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
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: OceanColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: OceanColors.ink,
                    fontWeight: FontWeight.w800,
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
    this.color = OceanColors.gold,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
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
                  color: color,
                  fontWeight: FontWeight.w800,
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2B3E55),
            OceanColors.deepBlue,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.directions_boat_filled,
          color: OceanColors.gold,
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
