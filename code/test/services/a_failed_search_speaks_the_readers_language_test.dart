import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_catalog_service.dart';

/// A plugin search that fails says so in the reader's language.
///
/// The panel printed what the service had written, and the service writes
/// English. So the marketplace spoke twelve languages while it worked and one
/// the moment it stopped — the moment a reader most needs to understand what
/// happened, and the same fault this suite already caught once in the dialog
/// that reports a failed AI configuration test.
///
/// The failure carries a kind now, the way `MermaidFailureKind` has since
/// diagrams needed it. Two of the three kinds are something a reader can act
/// on — no network, or GitHub asking them to wait — and those are translated;
/// the third is technical and stays as it came.
void main() {
  test('nothing reaching GitHub is a kind, not a sentence', () {
    final failure = PluginCatalogService.classify(
      const SocketException('whatever the platform said'),
    );
    expect(failure.kind, PluginCatalogFailureKind.unreachable);
  });

  test('rate limiting keeps the seconds, which is the actionable part', () {
    final failure = PluginCatalogService.failureFor(
      status: HttpStatus.forbidden,
      remaining: '0',
      resetAt: DateTime.now().add(const Duration(seconds: 90)),
    );
    expect(failure.kind, PluginCatalogFailureKind.rateLimited);
    expect(failure.retryAfter, closeTo(90, 2),
        reason: '秒数是读者唯一能据以行动的信息，不能只留在英文句子里');
  });

  test('and survives being thrown, which is the whole point', () {
    // The seconds are worked out from a response header. Thrown as a sentence,
    // there is no reading them back out afterwards — so the kind has to travel
    // with the exception.
    final thrown = PluginCatalogException(
      PluginCatalogService.failureFor(
        status: 429,
        remaining: '0',
        resetAt: DateTime.now().add(const Duration(seconds: 30)),
      ),
    );
    final classified = PluginCatalogService.classify(thrown);
    expect(classified.kind, PluginCatalogFailureKind.rateLimited);
    expect(classified.retryAfter, closeTo(30, 2));
  });

  test('a limit with no reset time is still a limit', () {
    final failure = PluginCatalogService.failureFor(
      status: HttpStatus.forbidden,
      remaining: '0',
      resetAt: null,
    );
    expect(failure.kind, PluginCatalogFailureKind.rateLimited);
    expect(failure.retryAfter, isNull);
  });

  test('an ordinary refusal is technical, and says so', () {
    // 403 with requests still remaining is not rate limiting; it is something
    // else, and pretending to know which would send the reader to wait for a
    // limit that will never lift.
    final failure = PluginCatalogService.failureFor(
      status: HttpStatus.forbidden,
      remaining: '57',
      resetAt: null,
    );
    expect(failure.kind, PluginCatalogFailureKind.other);
    expect(failure.detail, contains('403'));
  });

  test('the English wording has one source, so it cannot drift', () {
    // `describeFailure` is what the automation interface reads, and it is now
    // the failure rendered. Two spellings of the same sentence is how the two
    // halves of this come apart.
    final failure = PluginCatalogService.failureFor(
      status: 500, remaining: null, resetAt: null,
    );
    expect(
      PluginCatalogService.describeFailure(
          status: 500, remaining: null, resetAt: null),
      failure.describe(),
    );
  });
}
