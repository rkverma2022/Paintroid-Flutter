import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paintroid/command/src/command_factory.dart';
import 'package:paintroid/command/src/command_manager.dart';
import 'package:paintroid/tool/src/hand_tool/hand_tool.dart';
import 'package:paintroid/tool/src/tool_types.dart';

import 'hand_tool_test.mocks.dart';

@GenerateMocks([
  Paint,
  CommandManager,
  CommandFactory,
])
void main() {
  late MockPaint mockPaint;
  late MockCommandFactory mockCommandFactory;
  late MockCommandManager mockCommandManager;

  late HandTool sut;
  const Offset offset = Offset(10, 10);

  setUp(() {
    mockPaint = MockPaint();
    mockCommandFactory = MockCommandFactory();
    mockCommandManager = MockCommandManager();

    sut = HandTool(
      paint: mockPaint,
      commandFactory: mockCommandFactory,
      commandManager: mockCommandManager,
      type: ToolType.HAND,
    );
  });

  group('HandTool Tests', () {
    test('onDown should not interact with any dependencies', () {
      sut.onDown(offset);

      verifyNoMoreInteractions(mockPaint);
      verifyNoMoreInteractions(mockCommandFactory);
      verifyNoMoreInteractions(mockCommandManager);
    });

    test('onDrag should not interact with any dependencies', () {
      sut.onDrag(offset);

      verifyNoMoreInteractions(mockPaint);
      verifyNoMoreInteractions(mockCommandFactory);
      verifyNoMoreInteractions(mockCommandManager);
    });

    test('onUp should not interact with any dependencies', () {
      sut.onUp(offset);

      verifyNoMoreInteractions(mockPaint);
      verifyNoMoreInteractions(mockCommandFactory);
      verifyNoMoreInteractions(mockCommandManager);
    });

    test('onCancel should not interact with any dependencies', () {
      sut.onCancel();

      verifyNoMoreInteractions(mockPaint);
      verifyNoMoreInteractions(mockCommandFactory);
      verifyNoMoreInteractions(mockCommandManager);
    });
  });
}
