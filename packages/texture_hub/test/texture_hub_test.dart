import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:texture_hub/texture_hub.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter.plugins.io/texture_hub');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    // ignore: always_specify_types
    final slot = await TextureHub.allocate(tag: 'x', keepLatest: true);
    expect(slot.handle, 1);
    expect(slot.tag, 'x');
    expect(slot.keepLatest, true);
  });
}
