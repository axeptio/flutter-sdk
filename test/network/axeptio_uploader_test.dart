import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:axeptio_sdk/src/network/axeptio_uploader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tick = Duration(milliseconds: 20);

Map<String, dynamic> _proof(String identifier) {
  return {
    'preferences': {
      'config': {'identifier': identifier},
    },
    'accept': true,
  };
}

void main() {
  late List<http.Request> requests;
  late List<int> statuses;
  Completer<void>? gate;
  late SharedPreferences prefs;
  late AxeptioUploader uploader;
  final random = Random();

  http.Client client() {
    return MockClient((request) async {
      requests.add(request);
      await gate?.future;
      final status = statuses.isNotEmpty ? statuses.removeAt(0) : 200;
      if (status < 0) throw const SocketExceptionStub();
      return http.Response('', status);
    });
  }

  Future<AxeptioUploader> create() async {
    prefs = await SharedPreferences.getInstance();
    return AxeptioUploader(
      prefs,
      client(),
      proofRetryInterval: _tick,
      flushInterval: _tick,
    );
  }

  setUp(() async {
    requests = [];
    statuses = [];
    gate = null;
    SharedPreferences.setMockInitialValues({});
    uploader = await create();
  });

  tearDown(() => uploader.dispose());

  group('consent proof', () {
    test('posts consent:saved payload to the app consents endpoint', () async {
      // test: regression MSK-301, 3.0.0 never uploaded the consent proof
      final id = 'cfg-${random.nextInt(1 << 30)}';
      await uploader.sendConsentProof('client 1', _proof(id));

      expect(requests, hasLength(1));
      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url.host, 'api.axept.io');
      final segments = request.url.pathSegments;
      expect(segments, ['v1', 'app', 'consents', 'client 1', 'cookies', id]);
      expect(request.headers['Content-Type'], startsWith('application/json'));
      expect(request.headers['User-Agent'], startsWith('AxeptioFlutterSDK'));
      expect(jsonDecode(request.body), _proof(id));
      expect(uploader.hasPendingConsentProof, isFalse);
    });

    test('ignores a payload without a configuration identifier', () async {
      await uploader.sendConsentProof('cid', {'accept': true});
      await uploader.sendConsentProof('cid', null);
      await uploader.sendConsentProof('cid', {'preferences': 'x'});
      await uploader.sendConsentProof('cid', {
        'preferences': {'config': 'x'},
      });
      await uploader.sendConsentProof('cid', {
        'preferences': {
          'config': {'identifier': ''},
        },
      });

      expect(requests, isEmpty);
      expect(uploader.hasPendingConsentProof, isFalse);
    });

    test('keeps the proof and retries until the server accepts it', () async {
      statuses = [500, -1, 200];
      await uploader.sendConsentProof('cid', _proof('cfg'));
      expect(uploader.hasPendingConsentProof, isTrue);

      await Future.delayed(_tick * 8);

      expect(requests, hasLength(3));
      expect(uploader.hasPendingConsentProof, isFalse);
    });

    test('replays a persisted proof on start', () async {
      statuses = [503];
      await uploader.sendConsentProof('cid', _proof('cfg'));
      uploader.dispose();

      uploader = await create();
      await uploader.start();

      expect(requests, hasLength(2));
      expect(requests.last.url.pathSegments.last, 'cfg');
      expect(uploader.hasPendingConsentProof, isFalse);
    });

    test('cancel stops retries and drops the persisted proof', () async {
      statuses = [500, 500, 500];
      await uploader.sendConsentProof('cid', _proof('cfg'));
      await uploader.cancelConsentProof();

      await Future.delayed(_tick * 4);

      expect(requests, hasLength(1));
      expect(uploader.hasPendingConsentProof, isFalse);
    });

    test('a newer proof supersedes the pending one', () async {
      statuses = [500];
      await uploader.sendConsentProof('cid', _proof('old'));
      await uploader.sendConsentProof('cid', _proof('new'));

      await Future.delayed(_tick * 4);

      expect(requests.map((r) => r.url.pathSegments.last), ['old', 'new']);
      expect(uploader.hasPendingConsentProof, isFalse);
    });
  });

  group('analytics events', () {
    Map<String, dynamic> event(int i) => {'type': 'cookies:open', 'n': i};

    test('posts queued events as a JSON array after the interval', () async {
      // test: regression MSK-301, 3.0.0 dropped analytics:collect
      await uploader.enqueueEvent(event(1));
      await uploader.enqueueEvent(event(2));
      expect(requests, isEmpty);
      expect(uploader.queuedEvents, hasLength(2));

      await Future.delayed(_tick * 3);

      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/v1/analytics/evts');
      expect(jsonDecode(requests.single.body), [event(1), event(2)]);
      expect(uploader.queuedEvents, isEmpty);
    });

    test('ignores null events', () async {
      await uploader.enqueueEvent(null);
      expect(uploader.queuedEvents, isEmpty);
    });

    test('sends batches of 20', () async {
      final count = 41 + random.nextInt(10);
      final events = List.generate(count, (i) => jsonEncode(event(i)));
      await prefs.setStringList(AxeptioUploader.eventQueueKey, events);

      await uploader.flushEvents();

      final sizes = requests.map((r) => (jsonDecode(r.body) as List).length);
      expect(sizes, [20, 20, count - 40]);
      expect(uploader.queuedEvents, isEmpty);
    });

    test('keeps unsent batches queued and retries them', () async {
      statuses = [200, 500];
      final events = List.generate(25, (i) => jsonEncode(event(i)));
      await prefs.setStringList(AxeptioUploader.eventQueueKey, events);

      await uploader.flushEvents();
      expect(uploader.queuedEvents, hasLength(5));

      await Future.delayed(_tick * 3);
      expect(requests, hasLength(3));
      expect(uploader.queuedEvents, isEmpty);
    });

    test('persists the queue and flushes it on start', () async {
      statuses = [500];
      await uploader.enqueueEvent(event(1));
      await uploader.flushEvents();
      uploader.dispose();

      uploader = await create();
      expect(uploader.queuedEvents, hasLength(1));
      await uploader.start();

      expect(requests, hasLength(2));
      expect(uploader.queuedEvents, isEmpty);
    });

    test('caps the persisted queue by dropping the oldest events', () async {
      const max = AxeptioUploader.maxQueuedEvents;
      final queued = List.generate(max, (i) => jsonEncode(event(i)));
      await prefs.setStringList(AxeptioUploader.eventQueueKey, queued);

      await uploader.enqueueEvent(event(-1));

      final queue = uploader.queuedEvents;
      expect(queue, hasLength(max));
      expect(queue.first, jsonEncode(event(1)));
      expect(queue.last, jsonEncode(event(-1)));
    });

    test('a flush in flight when disposed schedules nothing', () async {
      // test: Copilot review 5702538949, disposed uploader kept retrying
      gate = Completer<void>();
      await uploader.enqueueEvent(event(1));
      final flush = uploader.flushEvents();
      uploader.dispose();
      statuses = [500];
      gate!.complete();
      await flush;

      await Future.delayed(_tick * 3);

      expect(requests, hasLength(1));
    });

    test('concurrent enqueues keep every event', () async {
      // test: Copilot r4415848599, read and write share no await
      await Future.wait([
        for (var i = 0; i < 10; i++) uploader.enqueueEvent(event(i)),
      ]);
      expect(uploader.queuedEvents, hasLength(10));
    });

    test('a concurrent flush is a no-op', () async {
      await uploader.enqueueEvent(event(1));
      await Future.wait([uploader.flushEvents(), uploader.flushEvents()]);
      expect(requests, hasLength(1));
    });
  });
}

class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
