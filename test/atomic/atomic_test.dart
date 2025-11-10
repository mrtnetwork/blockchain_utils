import 'dart:async';

import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:test/test.dart';

void main() {
  group('SafeAtomicLock', () {
    late SafeAtomicLock lock;

    setUp(() {
      lock = SafeAtomicLock();
    });

    test('executes tasks sequentially on the same lock', () async {
      final order = <int>[];

      for (int i = 0; i < 3; i++) {
        lock.run(() async {
          await Future.delayed(Duration(milliseconds: 100 - i));
          order.add(i);
        }, lockId: LockId.one);
      }

      await Future.delayed(const Duration(milliseconds: 400));
      expect(order, equals([0, 1, 2]));
    });

    test('allows tasks on different locks to run concurrently', () async {
      final events = <String>[];

      lock.run(() async {
        events.add('A-start');
        await Future.delayed(const Duration(milliseconds: 150));
        events.add('A-end');
      }, lockId: LockId.one);

      lock.run(() async {
        events.add('B-start');
        await Future.delayed(const Duration(milliseconds: 50));
        events.add('B-end');
      }, lockId: LockId.two);

      await Future.delayed(const Duration(milliseconds: 250));

      // "B" should finish before "A" because locks are independent
      final bEndIndex = events.indexOf('B-end');
      final aEndIndex = events.indexOf('A-end');
      expect(bEndIndex, lessThan(aEndIndex));
    });

    test('continues execution after an exception', () async {
      final results = <String>[];

      // First task throws
      lock.run(() async {
        Future<void> err() async {
          results.add('error-start');
          await Future.delayed(const Duration(milliseconds: 50));
          throw Exception('Boom');
        }

        await err();
        return null;
      }, lockId: LockId.one).catchError((_) => null);

      // Next task should still run
      lock.run(() async {
        results.add('after-error');
      }, lockId: LockId.one);

      await Future.delayed(const Duration(milliseconds: 200));

      expect(results, containsAllInOrder(['error-start', 'after-error']));
    });

    test('cleans up automatically after all tasks complete', () async {
      for (int i = 0; i < 2; i++) {
        lock.run(() async {
          await Future.delayed(const Duration(milliseconds: 50));
        }, lockId: LockId.one);
      }

      await Future.delayed(const Duration(milliseconds: 200));
      expect(lock.activeLocks, equals(0));
    });

    test('clearAll() manually clears active locks', () async {
      lock.run(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      }, lockId: LockId.one);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(lock.activeLocks, equals(1));

      lock.clearAll();
      expect(lock.activeLocks, equals(0));
    });
  });
}
