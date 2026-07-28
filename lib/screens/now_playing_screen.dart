import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/station.dart';
import '../services/favorites_service.dart';
import '../services/radio_player.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({
    super.key,
    required this.player,
    required this.favorites,
  });

  final RadioPlayer player;
  final FavoritesService favorites;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([player, favorites]),
      builder: (context, _) {
        final station = player.current;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.nowPlayingTitle)),
          body: station == null
              ? const _NothingPlaying()
              : _Details(
                  station: station,
                  player: player,
                  favorites: favorites,
                ),
        );
      },
    );
  }
}

class _NothingPlaying extends StatelessWidget {
  const _NothingPlaying();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.nothingPlaying,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.station,
    required this.player,
    required this.favorites,
  });

  final Station station;
  final RadioPlayer player;
  final FavoritesService favorites;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final stream = player.currentStream;
    final isFavorite = favorites.isFavorite(station.id);
    final track = player.nowPlayingTitle ?? player.nowPlaying;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                player.isPlaying ? Icons.graphic_eq_rounded : Icons.radio_rounded,
                size: 32,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                station.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            IconButton(
              tooltip: isFavorite ? l10n.removeFavorite : l10n.addFavorite,
              onPressed: () => favorites.toggle(station.id),
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? scheme.error : scheme.outline,
              ),
            ),
          ],
        ),
        if (track != null) ...[
          const SizedBox(height: 20),
          _TrackCard(title: track, artist: player.nowPlayingArtist),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: player.loading ? null : player.togglePlayPause,
                icon: Icon(
                  player.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(player.isPlaying ? l10n.pause : l10n.play),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: player.loading ? null : player.stop,
              icon: const Icon(Icons.stop_rounded),
              label: Text(l10n.stop),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: player.loading ? null : player.refreshCurrentStream,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.refreshStream),
          ),
        ),
        const SizedBox(height: 24),
        _InfoRow(
          label: l10n.quality,
          value: _qualityLabel(
            player.icyBitrate ?? stream?.bitrate,
            stream?.codec,
          ),
        ),
        _InfoRow(
          label: l10n.homepage,
          value: stream?.homepage ?? player.icyUrl,
          copyable: true,
        ),
      ],
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({required this.title, required this.artist});

  final String title;
  final String? artist;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onAir,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 0.6,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (artist != null && artist != title) ...[
            const SizedBox(height: 4),
            Text(
              artist!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final String label;
  final String? value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final known = value != null && value!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              known ? value! : '—',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: known
                        ? scheme.onSurface
                        : scheme.onSurface.withValues(alpha: 0.4),
                  ),
            ),
          ),
          if (copyable && known)
            InkWell(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: value!));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.copied(label))),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: scheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String? _qualityLabel(int? kbps, String? codec) {
  final parts = [
    if (kbps != null && kbps > 0) '$kbps kbps',
    if (codec != null && codec.isNotEmpty) codec.toUpperCase(),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}
