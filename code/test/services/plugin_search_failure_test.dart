import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_catalog_service.dart';

/// What the panel says when a search does not come back.
///
/// GitHub allows ten unauthenticated searches a minute, and pressing the
/// button a few times in a row reaches that. "returned 403" reads as the
/// plugin list being broken, which sends the reader looking for a fault that
/// is not there; it is a wait.
void main() {
  test('a rate limit says so, and says how long', () {
    final message = PluginCatalogService.describeFailure(
      status: HttpStatus.forbidden,
      remaining: '0',
      resetAt: DateTime.now().add(const Duration(seconds: 42)),
    );
    expect(message.toLowerCase(), contains('rate'));
    expect(message, contains('4'), reason: '要说还要等多久');
  });

  test('a rate limit whose window already passed still says to wait', () {
    final message = PluginCatalogService.describeFailure(
      status: 429,
      remaining: '0',
      resetAt: DateTime.now().subtract(const Duration(seconds: 5)),
    );
    expect(message.toLowerCase(), contains('rate'));
    expect(message, isNot(matches(RegExp(r'-\d'))), reason: '不能说等负几秒');
  });

  test('a forbidden that is not a rate limit is not called one', () {
    // A private repository, a blocked network. Telling the reader to wait a
    // minute would send them to wait for something that will not change.
    final message = PluginCatalogService.describeFailure(
      status: HttpStatus.forbidden,
      remaining: '17',
      resetAt: null,
    );
    expect(message, contains('403'));
    expect(message.toLowerCase(), isNot(contains('rate')));
  });

  test('any other failure carries its status', () {
    final message = PluginCatalogService.describeFailure(
      status: HttpStatus.internalServerError,
      remaining: null,
      resetAt: null,
    );
    expect(message, contains('500'));
  });
}
