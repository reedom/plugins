import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const MethodChannel _channel = MethodChannel('flutter.plugins.io/texture_hub');

class TextureSlot {
  TextureSlot._({
    this.handle,
    this.tag,
    this.useCopy,
    this.keepLatest
  }) : assert(0 < handle);

  factory TextureSlot._fromMap(Map<String, dynamic> m) {
    return TextureSlot._(
      handle: m['handle'],
      tag: m['tag'],
      useCopy: m['useCopy'],
      keepLatest: m['keepLatest'],
    )
      .._textureId = m['textureId'];
  }

  final int handle;
  final String tag;
  final bool keepLatest;
  final bool useCopy;
  bool _active = true;
  int _textureId;

  bool get active => _active;

  int get textureId => _textureId;

  Future<void> _allocate({bool useTextureWidget}) async {
    final Map<dynamic, dynamic> ret = await _channel.invokeMethod(
      'allocateSlot',
      <String, dynamic>{
        'handle': handle,
        'tag': tag,
        'keepLatest': keepLatest,
        'useCopy': useCopy,
        'useTextureWidget': useTextureWidget,
      },
    );
    _textureId = ret['textureId'];
  }

  Future<void> deallocate() async {
    if (!_active) return;

    _active = false;
    await _channel.invokeMethod<void>(
      'deallocateSlot',
      <String, dynamic>{'handle': handle},
    );
  }

  /// Get a [Texture] widget if the slot is active and has created a Texture.
  /// Otherwise it returns null.
  Texture getTexture({Key key}) {
    if (_active && textureId != null) {
      return Texture(textureId: textureId, key: key);
    }
    return null;
  }

  /// Get a [Texture] widget, the slot will create it if needed.
  /// It returns null if the slot has already been deallocated.
  Future<Texture> getOrCreateTexture({Key key}) async {
    if (_active && textureId == null) {
      final Map<dynamic, dynamic> ret = await _channel.invokeMethod(
        'createTexture',
        <String, dynamic>{'handle': handle},
      );
      _textureId = ret['textureId'];
    }
    return getTexture(key: key);
  }
}

class TextureHub {
  TextureHub._();

  static int _nextHandle = 1;

  static Future<TextureSlot> allocate({
    String tag,
    bool keepLatest,
    bool useTextureWidget,
  }) async {
    final TextureSlot slot = TextureSlot._(
      handle: _nextHandle++,
      tag: tag,
      keepLatest: keepLatest,
    );
    await slot._allocate(useTextureWidget: useTextureWidget);
    return slot;
  }

  static Future<List<TextureSlot>> list() async {
    final List<Map<String, dynamic>> list =
    await _channel.invokeMethod('listSlots');
    return list.map((Map<String, dynamic> m) => TextureSlot._fromMap(m));
  }
}
