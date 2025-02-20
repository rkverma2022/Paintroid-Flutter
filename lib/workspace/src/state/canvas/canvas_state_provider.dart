import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:paintroid/command/command.dart';
import 'package:paintroid/command/src/command_manager_provider.dart';
import 'package:paintroid/core/graphic_factory_provider.dart';
import 'package:paintroid/service/device_service.dart';
import 'package:paintroid/workspace/src/state/canvas/canvas_state_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'canvas_state_provider.g.dart';

@Riverpod(keepAlive: true)
class CanvasState extends _$CanvasState {
  Size initialCanvasSize = Size.zero;

  @override
  CanvasStateData build() {
    initialCanvasSize = ref.watch(IDeviceService.sizeProvider).when(
          data: (size) => size,
          error: (_, __) => widgets.WidgetsBinding.instance.platformDispatcher
              .views.first.physicalSize,
          loading: () => Size.zero,
        );
    return CanvasStateData(
      size: initialCanvasSize,
      commandManager: ref.watch(commandManagerProvider),
      graphicFactory: ref.watch(graphicFactoryProvider),
    );
  }

  void setBackgroundImage(Image image) => state = state.copyWith(
        backgroundImage: image,
        size: Size(image.width.toDouble(), image.height.toDouble()),
      );

  void clearBackgroundImageAndResetDimensions() => state = state.copyWith(
        backgroundImage: null,
        size: initialCanvasSize,
      );

  Future<void> updateCachedImage() async {
    final recorder = state.graphicFactory.createPictureRecorder();
    final canvas = state.graphicFactory.createCanvasWithRecorder(recorder);
    final size = state.size;
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    if (state.cachedImage != null) {
      paintImage(
        canvas: canvas,
        rect: bounds,
        image: state.cachedImage!,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
      );
    }
    canvas.clipRect(bounds);
    state.commandManager.executeLastCommand(canvas);
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    state = state.copyWith(cachedImage: img);
  }

  Future<void> resetCanvasWithNewCommands(Iterable<Command> commands) async {
    state.commandManager.clearHistory(newCommands: commands);
    if (commands.isEmpty) {
      state = state.copyWith(cachedImage: null);
    } else {
      final recorder = state.graphicFactory.createPictureRecorder();
      final canvas = state.graphicFactory.createCanvasWithRecorder(recorder);
      final size = state.size;
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
      state.commandManager.executeAllCommands(canvas);
      final picture = recorder.endRecording();
      final img =
          await picture.toImage(size.width.toInt(), size.height.toInt());
      state = state.copyWith(cachedImage: img);
    }
  }
}
