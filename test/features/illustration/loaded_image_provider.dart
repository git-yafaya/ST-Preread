import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// 一订阅就同步给出一张现成图片的图片来源，用来验证「图片读出来之后」的排版。
class LoadedImageProvider extends ImageProvider<LoadedImageProvider> {
  LoadedImageProvider(this.loadedImage);

  final ui.Image loadedImage;

  @override
  Future<LoadedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<LoadedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    LoadedImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      SynchronousFuture<ImageInfo>(ImageInfo(image: loadedImage.clone())),
    );
  }
}
