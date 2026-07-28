import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/app_settings.dart';
import 'services/favorites_service.dart';
import 'services/radio_audio_handler.dart';
import 'services/radio_player.dart';
import 'services/station_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final stations = StationRepository();
  await stations.load();
  final settings = AppSettings();
  await settings.load();
  final audioHandler = await initAudioService(stations, settings);
  final favorites = FavoritesService(stations);
  await favorites.load();
  final player = RadioPlayer(audioHandler, stations, settings);
  runApp(
    InternetRadioApp(
      player: player,
      favorites: favorites,
      stations: stations,
      settings: settings,
    ),
  );
}

class InternetRadioApp extends StatelessWidget {
  const InternetRadioApp({
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
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B6B5A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B6B5A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(
        player: player,
        favorites: favorites,
        stations: stations,
        settings: settings,
      ),
    );
  }
}
