/// Parses YouTube Shorts URLs and custom app deep links into video IDs.
class ShortUrlParser {
  ShortUrlParser._();

  static final RegExp _videoIdPattern = RegExp(r'^[\w-]{11}$');

  static final RegExp _shortsPath = RegExp(
    r'(?:youtube\.com|youtube-nocookie\.com|youtu\.be)/shorts/([\w-]{11})',
    caseSensitive: false,
  );

  static final RegExp _watchQuery = RegExp(
    r'[?&]v=([\w-]{11})',
    caseSensitive: false,
  );

  static final RegExp _youtuBe = RegExp(
    r'youtu\.be/([\w-]{11})',
    caseSensitive: false,
  );

  static final RegExp _appScheme = RegExp(
    r'^ytsk://short/([\w-]{11})/?$',
    caseSensitive: false,
  );

  /// Returns true when [input] clearly refers to a Shorts URL or app deep link.
  static bool isShortsUrl(String input) {
    final uri = _tryParse(input);
    if (uri == null) {
      return _appScheme.hasMatch(input.trim());
    }

    if (uri.scheme == 'ytsk' && uri.host == 'short') {
      return _validId(uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '');
    }

    final host = uri.host.toLowerCase();
    final isYoutubeHost = host.contains('youtube.com') ||
        host == 'youtu.be' ||
        host.contains('youtube-nocookie.com');
    if (!isYoutubeHost) return false;

    final path = uri.path.toLowerCase();
    if (path.contains('/shorts/')) return true;

    // Watch URLs that YouTube serves as Shorts often redirect to /shorts/.
    // Treat explicit shorts query hints as shorts.
    if (uri.queryParameters.containsKey('feature') &&
        uri.queryParameters['feature']?.toLowerCase() == 'share') {
      // Not enough alone — require /shorts/ or app scheme for false-positive safety
      // unless path already matched above.
    }

    return false;
  }

  /// Extracts an 11-char YouTube video id from Shorts URLs, watch URLs,
  /// youtu.be links, or `ytsk://short/{id}` deep links.
  ///
  /// For plain `/watch?v=` and `youtu.be` links, returns the id when present so
  /// the player can open a single embed (callers that only want confirmed
  /// Shorts paths should use [isShortsUrl] first, or [extractShortsVideoId]).
  static String? extractVideoId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final appMatch = _appScheme.firstMatch(trimmed);
    if (appMatch != null) return appMatch.group(1);

    final shortsMatch = _shortsPath.firstMatch(trimmed);
    if (shortsMatch != null) return shortsMatch.group(1);

    final uri = _tryParse(trimmed);
    if (uri != null) {
      if (uri.scheme == 'ytsk' && uri.host == 'short') {
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
        return _validId(id) ? id : null;
      }

      final path = uri.path;
      final shortsSegment = RegExp(
        r'/shorts/([\w-]{11})',
        caseSensitive: false,
      ).firstMatch(path);
      if (shortsSegment != null) return shortsSegment.group(1);

      final v = uri.queryParameters['v'];
      if (v != null && _validId(v)) return v;
    }

    final youtuMatch = _youtuBe.firstMatch(trimmed);
    if (youtuMatch != null) return youtuMatch.group(1);

    final watchMatch = _watchQuery.firstMatch(trimmed);
    if (watchMatch != null) return watchMatch.group(1);

    if (_validId(trimmed)) return trimmed;

    return null;
  }

  /// Like [extractVideoId] but only for confirmed Shorts paths or app scheme.
  static String? extractShortsVideoId(String input) {
    final trimmed = input.trim();
    if (_appScheme.hasMatch(trimmed)) {
      return extractVideoId(trimmed);
    }
    if (_shortsPath.hasMatch(trimmed)) {
      return extractVideoId(trimmed);
    }
    final uri = _tryParse(trimmed);
    if (uri == null) return null;
    if (uri.scheme == 'ytsk' && uri.host == 'short') {
      return extractVideoId(trimmed);
    }
    if (uri.path.toLowerCase().contains('/shorts/')) {
      return extractVideoId(trimmed);
    }
    return null;
  }

  static bool _validId(String id) => _videoIdPattern.hasMatch(id);

  static Uri? _tryParse(String input) {
    try {
      final uri = Uri.parse(input);
      if (uri.scheme.isEmpty) {
        return Uri.parse('https://$input');
      }
      return uri;
    } catch (_) {
      return null;
    }
  }
}
