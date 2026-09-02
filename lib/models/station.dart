enum StationRegion { israel, world }

/// Identity of a station in the catalog.
///
/// Stream URLs are not part of the identity: they are resolved from Radio
/// Browser at play time and cached by `StationRepository` until they fail.
class Station {
  const Station({
    required this.id,
    required this.name,
    required this.genre,
    required this.region,
    required this.searchName,
    this.subtitle,
    this.aliases = const <String>[],
    this.radioBrowserUuid,
    this.countryCode,
  });

  final String id;

  /// Name shown in the UI, in the station's own script.
  final String name;

  final String genre;
  final StationRegion region;

  /// Primary term used to query Radio Browser.
  final String searchName;

  final String? subtitle;

  /// Other names this station is legitimately known by. Used both as extra
  /// search terms and as accepted names when matching a Radio Browser hit.
  final List<String> aliases;

  final String? radioBrowserUuid;

  /// Narrows Radio Browser searches; null searches worldwide.
  final String? countryCode;

  /// Every name a Radio Browser hit may carry for this station.
  List<String> get matchNames => <String>{
        searchName,
        name,
        ...aliases,
      }.where((n) => n.trim().isNotEmpty).toList(growable: false);

  /// Query terms tried against Radio Browser, most distinctive first.
  List<String> get searchTerms => <String>{
        searchName,
        ...aliases,
      }
          .where((n) => n.trim().isNotEmpty)
          .take(3)
          .toList(growable: false);
}
