/// A playable stream URL for a station, plus whatever the directory knows
/// about it. Cached with [resolvedAt] so it can be refreshed periodically.
class ResolvedStream {
  const ResolvedStream({
    required this.streamUrl,
    required this.resolvedAt,
    this.bitrate,
    this.codec,
    this.homepage,
    this.countryCode,
    this.language,
    this.radioBrowserName,
    this.radioBrowserUuid,
  });

  final String streamUrl;
  final DateTime resolvedAt;

  /// True when [url] is an absolute http(s) URL with a host.
  static bool isPlayableUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  /// Nominal bitrate in kbps as reported by Radio Browser.
  final int? bitrate;

  final String? codec;
  final String? homepage;
  final String? countryCode;
  final String? language;
  final String? radioBrowserName;
  final String? radioBrowserUuid;

  Duration ageAt(DateTime now) => now.difference(resolvedAt);

  bool isFreshAt(DateTime now, Duration ttl) => ageAt(now) < ttl;

  DateTime expiresAfter(Duration ttl) => resolvedAt.add(ttl);

  Map<String, dynamic> toJson() => {
        'streamUrl': streamUrl,
        'resolvedAt': resolvedAt.millisecondsSinceEpoch,
        if (bitrate != null) 'bitrate': bitrate,
        if (codec != null) 'codec': codec,
        if (homepage != null) 'homepage': homepage,
        if (countryCode != null) 'countryCode': countryCode,
        if (language != null) 'language': language,
        if (radioBrowserName != null) 'radioBrowserName': radioBrowserName,
        if (radioBrowserUuid != null) 'radioBrowserUuid': radioBrowserUuid,
      };

  /// Returns null instead of throwing so one bad cache entry cannot break
  /// loading the rest of the cache.
  static ResolvedStream? tryFromJson(Map<String, dynamic> json) {
    final url = json['streamUrl'];
    final resolvedAt = json['resolvedAt'];
    if (url is! String ||
        !isPlayableUrl(url) ||
        resolvedAt is! int) {
      return null;
    }

    String? text(String key) {
      final value = json[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return ResolvedStream(
      streamUrl: url,
      resolvedAt: DateTime.fromMillisecondsSinceEpoch(resolvedAt),
      bitrate: (json['bitrate'] as num?)?.toInt(),
      codec: text('codec'),
      homepage: text('homepage'),
      countryCode: text('countryCode'),
      language: text('language'),
      radioBrowserName: text('radioBrowserName'),
      radioBrowserUuid: text('radioBrowserUuid'),
    );
  }
}
