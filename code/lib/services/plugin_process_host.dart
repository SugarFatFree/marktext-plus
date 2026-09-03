import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'plugin_logger.dart';
import 'plugin_process_registry.dart';

/// JSON-RPC-over-stdio host for one plugin process.
///
/// A plugin never shares the editor isolate. A hung request is bounded by a
/// timeout and terminates only that child process.
class PluginProcessHost {
  PluginProcessHost({
    required this.executable,
    required this.logger,
    this.arguments = const [],
    this.environment = const {},
    this.registry,
  });

  final String executable;
  final List<String> arguments;

  /// Added to the child's environment. The launch token travels here rather
  /// than in argv, which anything that can run `ps` may read.
  final Map<String, String> environment;
  final PluginLogger logger;

  /// Where this child is written down so a crash cannot orphan it.
  final PluginProcessRegistry? registry;
  Process? _process;
  int _nextId = 0;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  StreamSubscription<String>? _stdout;
  StreamSubscription<String>? _stderr;

  bool get isRunning => _process != null;

  /// How long a plugin gets to notice its stdin closed before it is killed.
  static const _shutdownGrace = Duration(seconds: 2);

  Future<void> start({List<String>? arguments, String? workingDirectory}) async {
    if (isRunning) return;
    final process = await Process.start(
      executable,
      arguments ?? this.arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: false,
    );
    _process = process;
    await registry?.record(process.pid, executable);
    _stdout = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleLine, onError: (Object error) => logger.error('$error'));
    _stderr = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => logger.error(line));
    // Deliberately not awaited: process exit is a lifecycle notification,
    // while start must return as soon as the child is ready.
    unawaited(process.exitCode.then((code) {
      logger.info('plugin process exited with code $code');
      for (final completer in _pending.values) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('plugin process exited'));
        }
      }
      _pending.clear();
      _process = null;
      // Deliberately not awaited: this runs inside an exit notification that
      // nothing waits on, and forgetting a dead child is bookkeeping — the
      // next start reaps whatever this misses.
      unawaited(registry?.forget(process.pid) ?? Future<void>.value());
    }));
    await logger.info('plugin process started');
  }

  Future<Map<String, dynamic>> call(
    String method, {
    Map<String, dynamic> params = const {},
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final process = _process;
    if (process == null) throw StateError('plugin process is not running');
    final id = ++_nextId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    process.stdin.writeln(jsonEncode({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': params}));
    try {
      return await completer.future.timeout(timeout, onTimeout: () {
        // Deliberately not awaited: timeout must reject this request now;
        // stopping the isolated child can finish independently.
        unawaited(stop());
        throw TimeoutException('plugin request timed out', timeout);
      });
    } finally {
      _pending.remove(id);
    }
  }

  void _handleLine(String line) {
    try {
      final message = jsonDecode(line) as Map<String, dynamic>;
      final id = message['id'];
      if (id is! int) return;
      final completer = _pending[id];
      if (completer == null || completer.isCompleted) return;
      final error = message['error'];
      if (error != null) {
        completer.completeError(StateError(error.toString()));
      } else {
        completer.complete(message);
      }
    } catch (error) {
      // Deliberately not awaited: malformed plugin output must not block the
      // stdout listener while the error is persisted.
      unawaited(logger.error('invalid plugin response: $error'));
    }
  }

  Future<void> stop() async {
    final process = _process;
    if (process == null) return;
    // Closing stdin is the signal a plugin is meant to shut down on; killing
    // it is what happens to a plugin that ignores that.
    try {
      await process.stdin.close();
    } catch (_) {
      // The child may already be gone, which is the outcome being asked for.
    }
    final exited = await process.exitCode
        .timeout(_shutdownGrace, onTimeout: () => -1)
        .then((code) => code != -1);
    if (!exited) process.kill();
    await registry?.forget(process.pid);
    await _stdout?.cancel();
    await _stderr?.cancel();
    _stdout = null;
    _stderr = null;
    _process = null;
    await logger.info('plugin process stopped');
  }
}
