import 'package:flutter_test/flutter_test.dart';
import 'package:ytscrolling_killer/core/short_url_parser.dart';

void main() {
  group('ShortUrlParser.extractShortsVideoId', () {
    test('parses youtube.com/shorts', () {
      expect(
        ShortUrlParser.extractShortsVideoId(
          'https://www.youtube.com/shorts/dQw4w9WgXcQ',
        ),
        'dQw4w9WgXcQ',
      );
    });

    test('parses m.youtube.com/shorts', () {
      expect(
        ShortUrlParser.extractShortsVideoId(
          'https://m.youtube.com/shorts/dQw4w9WgXcQ?feature=share',
        ),
        'dQw4w9WgXcQ',
      );
    });

    test('parses app deep link', () {
      expect(
        ShortUrlParser.extractShortsVideoId('ytsk://short/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('rejects plain watch urls', () {
      expect(
        ShortUrlParser.extractShortsVideoId(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        isNull,
      );
    });
  });

  group('ShortUrlParser.extractVideoId', () {
    test('parses youtu.be', () {
      expect(
        ShortUrlParser.extractVideoId('https://youtu.be/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('parses watch query', () {
      expect(
        ShortUrlParser.extractVideoId(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=10',
        ),
        'dQw4w9WgXcQ',
      );
    });

    test('parses bare video id', () {
      expect(ShortUrlParser.extractVideoId('dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    });
  });

  group('ShortUrlParser.isShortsUrl', () {
    test('true for shorts path', () {
      expect(
        ShortUrlParser.isShortsUrl('https://youtube.com/shorts/dQw4w9WgXcQ'),
        isTrue,
      );
    });

    test('true for app scheme', () {
      expect(ShortUrlParser.isShortsUrl('ytsk://short/dQw4w9WgXcQ'), isTrue);
    });

    test('false for home', () {
      expect(ShortUrlParser.isShortsUrl('https://www.youtube.com/'), isFalse);
    });
  });
}
