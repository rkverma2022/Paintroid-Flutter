import 'dart:ui';

import 'package:paintroid/core/graphic_factory_provider.dart';
import 'package:paintroid/tool/src/brush_tool/brush_tool_state_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'brush_tool_state_provider.g.dart';

@riverpod
class BrushToolState extends _$BrushToolState {
  void updateStrokeWidth(double newStrokeWidth) {
    Paint newPaint = state.paint..strokeWidth = newStrokeWidth;
    state = state.copyWith(paint: newPaint);
  }

  void updateStrokeCap(StrokeCap newStrokeCap) {
    Paint newPaint = state.paint..strokeCap = newStrokeCap;
    state = state.copyWith(paint: newPaint);
  }

  void updateColor(Color newColor) {
    Paint newPaint = state.paint..color = newColor;
    state = state.copyWith(paint: newPaint);
  }

  void updateBlendMode(BlendMode newMode) {
    Paint newPaint = state.paint..blendMode = newMode;
    state = state.copyWith(paint: newPaint);
  }

  @override
  BrushToolStateData build() {
    return BrushToolStateData(
      paint: ref.watch(graphicFactoryProvider).createPaint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF830000)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 25,
    );
  }
}
