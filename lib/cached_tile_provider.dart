import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CachedTileProvider extends TileProvider {
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = options.urlTemplate!
        .replaceFirst('{x}', coordinates.x.toString())
        .replaceFirst('{y}', coordinates.y.toString())
        .replaceFirst('{z}', coordinates.z.toString())
        .replaceFirst('{s}', options.subdomains[coordinates.x % options.subdomains.length]);

    return _CachedImageProvider(url, _cacheManager);
  }
}

class _CachedImageProvider extends ImageProvider<_CachedImageProvider> {
  final String url;
  final DefaultCacheManager cacheManager;

  _CachedImageProvider(this.url, this.cacheManager);

  @override
  Future<_CachedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_CachedImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(_CachedImageProvider key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(_CachedImageProvider key) async {
    final file = await cacheManager.getSingleFile(url);
    final bytes = await file.readAsBytes();
    return await ui.instantiateImageCodec(bytes);
  }
}
