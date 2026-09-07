import 'dart:io';

/// Sends every `HttpClient` in this process through the reader's proxy.
///
/// Most of this editor's requests are made by code that can set `findProxy`
/// for itself, and four services do. The ones that cannot are the problem:
/// `Image.network` builds its client inside Flutter's painting layer, and
/// `package:http` builds one inside `IOClient`. Neither offers a hook, so a
/// remote picture in a document, and the update check, went straight out and
/// were dropped by the firewall — while the alt text in the error colour told
/// the reader their link was broken.
///
/// `HttpOverrides` is the only place that covers all of them at once, because
/// `HttpClient()` is a factory that asks it first. Installing one costs
/// nothing at startup: it sets a zone value, opens no socket and reads no
/// file. The environment is read once here, not per request.
///
/// A client that wants something different can still say so — this only
/// supplies the default that every unconfigured client picks up. The services
/// that set `findProxy` by hand keep working unchanged; they now agree with
/// the default instead of being the only ones that had it.
class SystemProxyHttpOverrides extends HttpOverrides {
  SystemProxyHttpOverrides({Map<String, String>? environment})
      : environment = environment ?? Platform.environment;

  /// `http_proxy`, `https_proxy` and `no_proxy`, as the process received them.
  ///
  /// Injectable so a test can state a proxy rather than depend on whether the
  /// machine running it happens to sit behind one.
  final Map<String, String> environment;

  /// Where a request for [uri] should go: a proxy, or `DIRECT`.
  ///
  /// Public because `HttpClient.findProxy` is a setter with no getter, so a
  /// test cannot ask a client what it decided. The rule is worth checking on
  /// its own — `no_proxy` in particular is easy to get wrong and invisible
  /// until someone is behind a proxy that does not reach an internal host.
  String proxyFor(Uri uri) => HttpClient.findProxyFromEnvironment(
        uri,
        environment: environment,
      );

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)..findProxy = proxyFor;
}
