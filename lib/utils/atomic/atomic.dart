import 'dart:async';

/// Unique IDs for different locks.
enum LockId { one, two, three, four, five }

typedef AsyncTask<T> = FutureOr<T> Function();

/// A hybrid atomic lock — safe, fast, and error-proof.
class SafeAtomicLock {
  final Map<LockId, Future<void>> _locks = {};

  /// Runs [task] atomically for the given [lockId].
  ///
  /// - Each [lockId] runs its tasks sequentially.
  /// - Different lock IDs run concurrently.
  /// - Exceptions never break the chain.
  /// - Cleans up automatically after each run.
  Future<T> run<T>(AsyncTask<T> task, {LockId lockId = LockId.one}) {
    // Get the previous task or an empty one
    final previous = _locks[lockId] ?? Future.value();

    final completer = Completer<void>.sync();
    // Register the new lock
    _locks[lockId] = completer.future;
    // Chain this task after the previous one
    final next = previous.then((_) async {
      try {
        return await Future.sync(task);
      } finally {
        // Cleanup to avoid memory leaks
        if (identical(_locks[lockId], completer.future)) {
          _locks.remove(lockId);
        }
        completer.complete();
      }
    });

    return next;
  }

  /// Manually clear all locks.
  void clearAll() => _locks.clear();

  /// Number of currently active locks.
  int get activeLocks => _locks.length;
}
