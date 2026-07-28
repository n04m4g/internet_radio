import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/radio_player.dart';

class NowPlayingBar extends StatelessWidget {
  const NowPlayingBar({super.key, required this.player, required this.onTap});

  final RadioPlayer player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final station = player.current;
    if (station == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hasTrackInfo = player.nowPlaying != null;

    return Material(
      elevation: 8,
      color: scheme.inverseSurface,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      Icon(Icons.radio, color: scheme.onInverseSurface),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              station.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: scheme.onInverseSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              player.nowPlayingSubtitle(l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onInverseSurface.withValues(
                                      alpha: hasTrackInfo ? 0.9 : 0.7,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: player.isPlaying ? l10n.pause : l10n.play,
              onPressed: player.loading ? null : player.togglePlayPause,
              icon: Icon(
                player.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: scheme.onInverseSurface,
                size: 32,
              ),
            ),
            IconButton(
              tooltip: l10n.stop,
              onPressed: player.loading ? null : player.stop,
              icon: Icon(
                Icons.stop_rounded,
                color: scheme.onInverseSurface,
                size: 32,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
