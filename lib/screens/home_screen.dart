import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/station.dart';
import '../services/app_settings.dart';
import '../services/favorites_service.dart';
import '../services/notification_permission.dart';
import '../services/radio_player.dart';
import '../services/station_repository.dart';
import '../widgets/now_playing_bar.dart';
import '../widgets/station_tile.dart';
import 'now_playing_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.player,
    required this.favorites,
    required this.stations,
    required this.settings,
  });

  final RadioPlayer player;
  final FavoritesService favorites;
  final StationRepository stations;
  final AppSettings settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  bool _notificationsBlocked = false;
  bool _permissionNoticeDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.player.maybeAutoPlayLastStation();
      _askForNotificationPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabs.dispose();
    super.dispose();
  }

  /// The user has to leave the app to undo a denial, so the state is rechecked
  /// on the way back in.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateNotificationState(notificationsBlocked());
    }
  }

  void _askForNotificationPermission() =>
      _updateNotificationState(requestNotificationPermission());

  Future<void> _updateNotificationState(Future<bool> check) async {
    final blocked = await check;
    if (!mounted || blocked == _notificationsBlocked) return;
    setState(() => _notificationsBlocked = blocked);
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          settings: widget.settings,
          stations: widget.stations,
        ),
      ),
    );
  }

  void _openNowPlaying() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NowPlayingScreen(
          player: widget.player,
          favorites: widget.favorites,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.player,
        widget.favorites,
        widget.stations,
      ]),
      builder: (context, _) {
        final banner = widget.player.error ?? widget.player.statusMessage;
        final isError = widget.player.error != null;
        final bannerForeground = isError
            ? Theme.of(context).colorScheme.onErrorContainer
            : Theme.of(context).colorScheme.onSecondaryContainer;

        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            l10n.appTitle,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.settingsTooltip,
                        onPressed: _openSettings,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  tabs: [
                    Tab(text: l10n.tabIsrael),
                    Tab(text: l10n.tabFavorites),
                    Tab(text: l10n.tabWorld),
                  ],
                ),
                if (_notificationsBlocked && !_permissionNoticeDismissed)
                  _NotificationNotice(
                    onOpenSettings: openNotificationSettings,
                    onDismiss: () =>
                        setState(() => _permissionNoticeDismissed = true),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      TabBarView(
                        controller: _tabs,
                        children: [
                          _StationList(
                            stations: widget.stations
                                .forRegion(StationRegion.israel),
                            player: widget.player,
                            favorites: widget.favorites,
                            emptyMessage: l10n.emptyIsraelStations,
                          ),
                          _StationList(
                            stations: widget.favorites.favorites,
                            player: widget.player,
                            favorites: widget.favorites,
                            emptyMessage: l10n.emptyFavorites,
                          ),
                          _StationList(
                            stations: widget.stations
                                .forRegion(StationRegion.world),
                            player: widget.player,
                            favorites: widget.favorites,
                            emptyMessage: l10n.emptyWorldStations,
                          ),
                        ],
                      ),
                      if (banner != null)
                        Positioned(
                          top: 8,
                          left: 20,
                          right: 20,
                          child: Material(
                            elevation: 4,
                            color: isError
                                ? Theme.of(context)
                                    .colorScheme
                                    .errorContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 4, 4, 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      banner,
                                      style: TextStyle(
                                        color: bannerForeground,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: l10n.dismissTooltip,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: widget.player.dismissBanner,
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: bannerForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                NowPlayingBar(player: widget.player, onTap: _openNowPlaying),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationNotice extends StatelessWidget {
  const _NotificationNotice({
    required this.onOpenSettings,
    required this.onDismiss,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Material(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.notificationsBlocked,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onDismiss,
                    child: Text(l10n.notNow),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: onOpenSettings,
                    child: Text(l10n.openSettings),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationList extends StatelessWidget {
  const _StationList({
    required this.stations,
    required this.player,
    required this.favorites,
    required this.emptyMessage,
  });

  final List<Station> stations;
  final RadioPlayer player;
  final FavoritesService favorites;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: stations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final station = stations[index];
        final selected = player.current?.id == station.id;
        return StationTile(
          station: station,
          selected: selected,
          playing: selected && player.isPlaying,
          loading: selected && player.loading,
          isFavorite: favorites.isFavorite(station.id),
          onTap: () => player.playStation(station),
          onFavoriteTap: () => favorites.toggle(station.id),
        );
      },
    );
  }
}
