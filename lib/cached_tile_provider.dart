import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = options.urlTemplate!
        .replaceFirst('{x}', coordinates.x.toString())
        .replaceFirst('{y}', coordinates.y.toString())
        .replaceFirst('{z}', coordinates.z.toString())
        .replaceFirst('{s}', options.subdomains[coordinates.x % options.subdomains.length]);

    return CachedNetworkImageProvider(url);
  }
}
