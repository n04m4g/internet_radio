import 'package:flutter/material.dart';

import '../models/station.dart';

class StationTile extends StatelessWidget {
  const StationTile({
    super.key,
    required this.station,
    required this.selected,
    required this.playing,
    required this.loading,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final Station station;
  final bool selected;
  final bool playing;
  final bool loading;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? scheme.primary : scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  playing ? Icons.graphic_eq_rounded : Icons.radio_rounded,
                  color: selected ? scheme.onPrimary : scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (station.subtitle != null) station.subtitle!,
                        station.genre,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
                onPressed: onFavoriteTap,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? scheme.error : scheme.outline,
                ),
              ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              else
                Icon(
                  playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 36,
                  color: selected ? scheme.primary : scheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
