// ignore_for_file: require_trailing_commas
import 'dart:io';

import 'package:drive/drive.dart' as drive;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'query_e2e.dart';

final List<Map<String, Object>> testDocuments = [
  {'ref': 'one', 'value': 23},
  {'ref': 'two', 'value': 56},
  {'ref': 'three', 'value': 9},
  {'ref': 'four', 'value': 40}
];

late FirebaseDatabase database;

Future<void> prepareData() async {
  await database.ref('flutterfire').set(0);

  final orderedRef = database.ref('ordered');

  await Future.wait(testDocuments.map((map) {
    String key = map['ref']! as String;
    return orderedRef.child(key).set(map);
  }));
}

const MAX_CACHE_SIZE = 100 * 1024 * 1024;
const MIN_CACHE_SIZE = 1042 * 1024;

void testsMain() {
  setUpAll(() async {
    database = FirebaseDatabase.instance;
    await Firebase.initializeApp();
  });

  group('FirebaseDatabase configuration', () {
    test('setPersistenceCacheSizeBytes Integer', () async {
      await database.setPersistenceCacheSizeBytes(MIN_CACHE_SIZE);
      // Skipped because it is not supported on web
    }, skip: kIsWeb);

    test('setPersistenceCacheSizeBytes Long', () async {
      await database.setPersistenceCacheSizeBytes(MAX_CACHE_SIZE);
      // Skipped because it is not supported on web
    }, skip: kIsWeb);

    test('setLoggingEnabled to true', () async {
      await database.setLoggingEnabled(true);
    });

    test('setLoggingEnabled to false', () async {
      await database.setLoggingEnabled(false);
    });
  });

  group('DatabaseReference', () {
    setUp(prepareData);

    test('runTransaction', () async {
      final DatabaseReference ref = database.ref('flutterfire');
      final DataSnapshot snapshot = await ref.get();

      final int value = snapshot.value ?? 0;
      final TransactionResult transactionResult =
          await ref.runTransaction((MutableData mutableData) {
        mutableData.value = (mutableData.value ?? 0) + 1;
        return mutableData;
      });

      expect(transactionResult.committed, true);
      expect(transactionResult.dataSnapshot!.value > value, true);
    });

    group('#ref()', () {
      setUp(prepareData);

      test('returns a correct reference', () async {
        final ref = FirebaseDatabase.instance.ref('flutterfire');
        final snapshot = await ref.get();
        expect(snapshot.value, 0);
      });

      test(
        'returns a reference to the root of the database if no path specified',
        () async {
          final ref = FirebaseDatabase.instance.ref().child('flutterfire');
          final snapshot = await ref.get();
          expect(snapshot.value, 0);
        },
      );
    });

    test('DataSnapshot supports null childKeys for maps', () async {
      // Regression test for https://github.com/FirebaseExtended/flutterfire/issues/6002

      final ref = FirebaseDatabase.instance.ref('flutterfire');

      final transactionResult = await ref.runTransaction((mutableData) {
        mutableData.value = {'v': 'vala'};
        return mutableData;
      });

      expect(transactionResult.committed, true);
      expect(
        transactionResult.dataSnapshot!.value,
        {'v': 'vala'},
      );
    });

    runQueryTests();
  });
}

void main() => drive.main(testsMain);
