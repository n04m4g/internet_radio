import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/station_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.stations,
  });

  final AppSettings settings;
  final StationRepository stations;

  Future<void> _clearCache(
    BuildContext context,
    ScaffoldMessengerState messenger,
  ) async {
    final message = AppLocalizations.of(context).streamCacheCleared;
    await stations.clearCache();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final last = settings.lastPlayedStationId == null
        ? null
        : stations.byId(settings.lastPlayedStationId!);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([settings, stations]),
        builder: (context, _) {
          final cached = stations.cachedStreamCount;
          return ListView(
            children: [
              const SizedBox(height: 8),
              SwitchListTile(
                secondary: const Icon(Icons.play_circle_outline),
                title: Text(l10n.autoPlayLastStation),
                subtitle: Text(
                  last == null
                      ? l10n.autoPlayLastStationHint
                      : l10n.autoPlayWillStartWith(last.name),
                ),
                value: settings.autoPlayLastStation,
                onChanged: settings.setAutoPlayLastStation,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.tune),
                title: Text(l10n.streamBuffer),
                subtitle: Text(settings.streamBufferSize.description(l10n)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SegmentedButton<StreamBufferSize>(
                  segments: [
                    for (final size in StreamBufferSize.values)
                      ButtonSegment(
                        value: size,
                        label: Text(size.label(l10n)),
                      ),
                  ],
                  selected: {settings.streamBufferSize},
                  onSelectionChanged: (selected) {
                    if (selected.isEmpty) return;
                    settings.setStreamBufferSize(selected.first);
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: Text(l10n.refreshStreamCache),
                subtitle: Text(
                  cached == 0
                      ? l10n.streamCacheEmpty
                      : l10n.streamCacheCount(cached),
                ),
                trailing: const Icon(Icons.delete_outline),
                enabled: cached > 0,
                onTap: cached == 0
                    ? null
                    : () => _clearCache(context, ScaffoldMessenger.of(context)),
              ),
              const Divider(),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '…';
                  return ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.aboutTitle),
                    subtitle: Text(l10n.aboutBody(version)),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
