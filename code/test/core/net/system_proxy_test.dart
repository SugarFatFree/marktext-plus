import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/net/system_proxy.dart';

/// Every request this editor makes follows the reader's proxy — including the
/// ones it does not write itself.
///
/// Four services set `findProxy` by hand and one did not: remote pictures in a
/// document go through `Image.network`, which builds its own `HttpClient` deep
/// inside Flutter where no call site of ours can reach it. Behind a corporate
/// proxy those pictures simply never arrived, and what the reader saw was the
/// alt text in the error colour — which looks like a broken link, not like a
/// setting that was never applied. `package:http` in the update check had the
/// same gap.
///
/// An `HttpOverrides` is the one place that catches all of them, because it is
/// the factory every `HttpClient()` in the process goes through.
void main() {
  test('a client built under the override goes to the proxy', () async {
    // The "proxy": anything that connects here is going through it rather
    // than straight to the origin.
    final proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => proxy.close(force: true));
    final asked = <String>[];
    proxy.listen((request) {
      // An absolute request line is how a proxy is addressed, and it is the
      // part that proves this was not a direct connection.
      asked.add(request.uri.toString());
      request.response
        ..write('ok')
        ..close();
    });

    final overrides = SystemProxyHttpOverrides(
      environment: {'http_proxy': '127.0.0.1:${proxy.port}'},
    );
    final client = overrides.createHttpClient(null);
    addTearDown(() => client.close(force: true));

    final response = await (await client.getUrl(
      Uri.parse('http://example.invalid/picture.png'),
    )).close();
    await response.drain<void>();

    expect(asked, ['http://example.invalid/picture.png'],
        reason: '走代理时请求行是绝对地址；直连的话这台服务器根本不会被碰到，'
            'example.invalid 也解析不出来');
  });

  test('with no proxy set, nothing is redirected', () async {
    final overrides = SystemProxyHttpOverrides(environment: const {});

    // "DIRECT" is what an unset environment means. Asserted on the resolved
    // value rather than on a connection, so it does not depend on this
    // machine having a network at all.
    expect(overrides.proxyFor(Uri.parse('http://example.invalid/')), 'DIRECT');
  });

  test('the app installs it', () {
    // Written and never installed is this repository's most repeated
    // mistake — six times counted, and an override that is never assigned
    // to `HttpOverrides.global` fails exactly that way: every unit test here
    // passes and nothing in the running editor changes.
    final source = File('lib/main.dart').readAsStringSync();
    expect(
      source,
      contains('HttpOverrides.global = SystemProxyHttpOverrides()'),
      reason: '装不上的覆盖等于没写',
    );
    // Ahead of the binding, so nothing has had a chance to build a client
    // before the default is in place.
    expect(
      source.indexOf('HttpOverrides.global'),
      lessThan(source.indexOf('WidgetsFlutterBinding.ensureInitialized')),
      reason: '要在任何人建 HttpClient 之前装好',
    );
  });

  test('no_proxy is honoured', () async {
    final overrides = SystemProxyHttpOverrides(
      environment: {'http_proxy': '127.0.0.1:1', 'no_proxy': 'example.invalid'},
    );

    expect(overrides.proxyFor(Uri.parse('http://example.invalid/')), 'DIRECT');
    expect(
      overrides.proxyFor(Uri.parse('http://elsewhere.invalid/')),
      contains('127.0.0.1:1'),
    );
  });
}
