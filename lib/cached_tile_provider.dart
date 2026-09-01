import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CachedTileProvider extends TileProvider {
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = options.urlTemplate
        .replaceFirst('{x}', coordinates.x.toString())
        .replaceFirst('{y}', coordinates.y.toString())
        .replaceFirst('{z}', coordinates.z.toString())
        .replaceFirst('{s}', options.subdomains[coordinates.x % options.subdomains.length]);

    return CachedNetworkImageProvider(url);
  }
}