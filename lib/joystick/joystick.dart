import 'package:bonfire/bonfire.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum KeyboardDirectionalType { arrows, wasd, wasdAndArrows }

class KeyboardConfig {
  /// Use to enable ou disable keyboard events
  final bool enable;

  /// Type of the directional (arrows, wasd or wasdAndArrows)
  final KeyboardDirectionalType keyboardDirectionalType;

  /// You can pass specific Keys accepted. If null accept all keys
  final List<LogicalKeyboardKey>? acceptedKeys;

  KeyboardConfig({
    this.enable = true,
    this.keyboardDirectionalType = KeyboardDirectionalType.arrows,
    this.acceptedKeys,
  }) {
    if (acceptedKeys != null) {
      switch (keyboardDirectionalType) {
        case KeyboardDirectionalType.arrows:
          acceptedKeys?.add(LogicalKeyboardKey.arrowLeft);
          acceptedKeys?.add(LogicalKeyboardKey.arrowRight);
          acceptedKeys?.add(LogicalKeyboardKey.arrowDown);
          acceptedKeys?.add(LogicalKeyboardKey.arrowUp);
          break;
        case KeyboardDirectionalType.wasd:
          acceptedKeys?.add(LogicalKeyboardKey.keyW);
          acceptedKeys?.add(LogicalKeyboardKey.keyS);
          acceptedKeys?.add(LogicalKeyboardKey.keyA);
          acceptedKeys?.add(LogicalKeyboardKey.keyD);
          break;
        case KeyboardDirectionalType.wasdAndArrows:
          acceptedKeys?.add(LogicalKeyboardKey.keyW);
          acceptedKeys?.add(LogicalKeyboardKey.keyS);
          acceptedKeys?.add(LogicalKeyboardKey.keyA);
          acceptedKeys?.add(LogicalKeyboardKey.keyD);
          acceptedKeys?.add(LogicalKeyboardKey.arrowLeft);
          acceptedKeys?.add(LogicalKeyboardKey.arrowRight);
          acceptedKeys?.add(LogicalKeyboardKey.arrowDown);
          acceptedKeys?.add(LogicalKeyboardKey.arrowUp);
          break;
      }
    }
  }
}

class Joystick extends JoystickController {
  final List<JoystickAction> actions;
  JoystickDirectional? _directional;

  JoystickDirectional? get directional => _directional;
  List<LogicalKeyboardKey> _currentKeyboardKeys = [];

  Joystick({
    this.actions = const [],
    JoystickDirectional? directional,
    KeyboardConfig? keyboardConfig,
  }) {
    _directional = directional;
    if (keyboardConfig != null) {
      this.keyboardConfig = keyboardConfig;
    }
  }

  void initialize(Vector2 size) async {
    directional?.initialize(size, this);
    actions.forEach((action) => action.initialize(size, this));
  }

  Future updateDirectional(JoystickDirectional? directional) async {
    directional?.initialize(gameRef.size, this);
    await directional?.onLoad();
    _directional = directional;
  }

  Future addAction(JoystickAction action) async {
    action.initialize(gameRef.size, this);
    await action.onLoad();
    actions.add(action);
  }

  void removeAction(dynamic actionId) {
    actions.removeWhere((action) => action.actionId == actionId);
  }

  void render(Canvas canvas) {
    super.render(canvas);
    directional?.render(canvas);
    for (JoystickAction action in actions) {
      action.render(canvas);
    }
  }

  @override
  void update(double dt) {
    directional?.update(dt);
    for (JoystickAction action in actions) {
      action.update(dt);
    }
    super.update(dt);
  }

  @override
  bool handlerPointerCancel(PointerCancelEvent event) {
    for (JoystickAction action in actions) {
      action.actionUp(event.pointer);
    }
    directional?.directionalUp(event.pointer);
    return super.handlerPointerCancel(event);
  }

  @override
  bool handlerPointerDown(PointerDownEvent event) {
    directional?.directionalDown(event.pointer, event.localPosition);
    for (JoystickAction action in actions) {
      action.actionDown(event.pointer, event.localPosition);
    }
    return super.handlerPointerDown(event);
  }

  @override
  bool handlerPointerMove(PointerMoveEvent event) {
    for (JoystickAction action in actions) {
      action.actionMove(event.pointer, event.localPosition);
    }
    directional?.directionalMove(event.pointer, event.localPosition);
    return super.handlerPointerMove(event);
  }

  @override
  bool handlerPointerUp(PointerUpEvent event) {
    for (JoystickAction action in actions) {
      action.actionUp(event.pointer);
    }
    directional?.directionalUp(event.pointer);
    return super.handlerPointerUp(event);
  }

  @override
  void onKeyboard(RawKeyEvent event) {
    if (!keyboardConfig.enable) return;

    if (_isDirectional(event)) {
      if (event is RawKeyDownEvent && _currentKeyboardKeys.length < 2) {
        if (!_currentKeyboardKeys.contains(event.logicalKey)) {
          _currentKeyboardKeys.add(event.logicalKey);
        }
      }

      if (event is RawKeyUpEvent && _currentKeyboardKeys.length > 0) {
        _currentKeyboardKeys.remove(event.logicalKey);
      }

      if (_currentKeyboardKeys.isEmpty) {
        joystickChangeDirectional(
          JoystickDirectionalEvent(
            directional: JoystickMoveDirectional.IDLE,
            intensity: 0.0,
            radAngle: 0.0,
          ),
        );
      } else {
        if (_currentKeyboardKeys.length == 1) {
          _sendOneDirection(_currentKeyboardKeys.first);
        } else {
          _sendTwoDirection(
            _currentKeyboardKeys.first,
            _currentKeyboardKeys[1],
          );
        }
      }
    } else {
      if (event is RawKeyDownEvent) {
        joystickAction(JoystickActionEvent(
          id: event.logicalKey.keyId,
          event: ActionEvent.DOWN,
        ));
      } else if (event is RawKeyUpEvent) {
        joystickAction(JoystickActionEvent(
          id: event.logicalKey.keyId,
          event: ActionEvent.UP,
        ));
      }
    }
  }

  @override
  void onGameResize(Vector2 gameSize) {
    initialize(gameRef.camera.canvasSize);
    super.onGameResize(gameSize);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await directional?.onLoad();
    await Future.forEach<JoystickAction>(
      actions,
      (element) => element.onLoad(),
    );
  }

  bool _isDirectional(RawKeyEvent event) {
    if (keyboardConfig.keyboardDirectionalType ==
        KeyboardDirectionalType.arrows) {
      return event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowDown;
    } else if (keyboardConfig.keyboardDirectionalType ==
        KeyboardDirectionalType.wasd) {
      return event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.keyW ||
          event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.keyS;
    } else {
      return event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.keyW ||
          event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.keyS ||
          event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowDown;
    }
  }

  void _sendOneDirection(LogicalKeyboardKey key) {
    switch (keyboardConfig.keyboardDirectionalType) {
      case KeyboardDirectionalType.arrows:
        _oneDirectionArrows(key);
        break;
      case KeyboardDirectionalType.wasd:
        _oneDirectionWASD(key);
        break;
      case KeyboardDirectionalType.wasdAndArrows:
        _oneDirectionWASDAndArrows(key);
    }
  }

  void _oneDirectionWASD(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.keyD) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_RIGHT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key == LogicalKeyboardKey.keyW) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_UP,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key == LogicalKeyboardKey.keyA) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_LEFT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key == LogicalKeyboardKey.keyS) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_DOWN,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }
  }

  void _oneDirectionArrows(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowRight) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_RIGHT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_UP,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key == LogicalKeyboardKey.arrowLeft) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_LEFT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_DOWN,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }
  }

  void _oneDirectionWASDAndArrows(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.arrowRight) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_RIGHT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key == LogicalKeyboardKey.keyW || key == LogicalKeyboardKey.arrowUp) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_UP,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key == LogicalKeyboardKey.keyA || key == LogicalKeyboardKey.arrowLeft) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_LEFT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key == LogicalKeyboardKey.keyS || key == LogicalKeyboardKey.arrowDown) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_DOWN,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }
  }

  void _sendTwoDirection(LogicalKeyboardKey key1, LogicalKeyboardKey key2) {
    switch (keyboardConfig.keyboardDirectionalType) {
      case KeyboardDirectionalType.arrows:
        _twoDirectionsArrows(key1, key2);
        break;
      case KeyboardDirectionalType.wasd:
        _twoDirectionsWASD(key1, key2);
        break;
      case KeyboardDirectionalType.wasdAndArrows:
        _twoDirectionsWASDAndArrows(key1, key2);
        break;
    }
  }

  void _twoDirectionsWASD(LogicalKeyboardKey key1, LogicalKeyboardKey key2) {
    if (key1 == LogicalKeyboardKey.keyD && key2 == LogicalKeyboardKey.keyS ||
        key2 == LogicalKeyboardKey.keyD && key1 == LogicalKeyboardKey.keyS) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_DOWN_RIGHT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key1 == LogicalKeyboardKey.keyA && key2 == LogicalKeyboardKey.keyS ||
        key2 == LogicalKeyboardKey.keyA && key1 == LogicalKeyboardKey.keyS) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_DOWN_LEFT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key1 == LogicalKeyboardKey.keyA && key2 == LogicalKeyboardKey.keyW ||
        key2 == LogicalKeyboardKey.keyA && key1 == LogicalKeyboardKey.keyW) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_UP_LEFT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key1 == LogicalKeyboardKey.keyD && key2 == LogicalKeyboardKey.keyW ||
        key2 == LogicalKeyboardKey.keyD && key1 == LogicalKeyboardKey.keyW) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_UP_RIGHT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }
  }

  void _twoDirectionsArrows(LogicalKeyboardKey key1, LogicalKeyboardKey key2) {
    if (key1 == LogicalKeyboardKey.arrowRight &&
            key2 == LogicalKeyboardKey.arrowDown ||
        key2 == LogicalKeyboardKey.arrowRight &&
            key1 == LogicalKeyboardKey.arrowDown) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_DOWN_RIGHT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key1 == LogicalKeyboardKey.arrowLeft &&
            key2 == LogicalKeyboardKey.arrowDown ||
        key2 == LogicalKeyboardKey.arrowLeft &&
            key1 == LogicalKeyboardKey.arrowDown) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_DOWN_LEFT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key1 == LogicalKeyboardKey.arrowLeft &&
            key2 == LogicalKeyboardKey.arrowUp ||
        key2 == LogicalKeyboardKey.arrowLeft &&
            key1 == LogicalKeyboardKey.arrowUp) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_UP_LEFT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if (key1 == LogicalKeyboardKey.arrowRight &&
            key2 == LogicalKeyboardKey.arrowUp ||
        key2 == LogicalKeyboardKey.arrowRight &&
            key1 == LogicalKeyboardKey.arrowUp) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_UP_RIGHT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }
  }

  void _twoDirectionsWASDAndArrows(
      LogicalKeyboardKey key1, LogicalKeyboardKey key2) {
    if ((key1 == LogicalKeyboardKey.arrowRight ||
                key1 == LogicalKeyboardKey.keyD) &&
            (key2 == LogicalKeyboardKey.arrowDown ||
                key2 == LogicalKeyboardKey.keyS) ||
        (key2 == LogicalKeyboardKey.arrowRight ||
                key2 == LogicalKeyboardKey.keyD) &&
            (key1 == LogicalKeyboardKey.arrowDown ||
                key1 == LogicalKeyboardKey.keyS)) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_DOWN_RIGHT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if ((key1 == LogicalKeyboardKey.arrowLeft ||
                key1 == LogicalKeyboardKey.keyA) &&
            (key2 == LogicalKeyboardKey.arrowDown ||
                key2 == LogicalKeyboardKey.keyS) ||
        (key2 == LogicalKeyboardKey.arrowLeft ||
                key2 == LogicalKeyboardKey.keyA) &&
            (key1 == LogicalKeyboardKey.arrowDown ||
                key1 == LogicalKeyboardKey.keyS)) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_DOWN_LEFT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if ((key1 == LogicalKeyboardKey.arrowLeft ||
                key1 == LogicalKeyboardKey.keyA) &&
            (key2 == LogicalKeyboardKey.arrowUp ||
                key2 == LogicalKeyboardKey.keyW) ||
        (key2 == LogicalKeyboardKey.arrowLeft ||
                key2 == LogicalKeyboardKey.keyA) &&
            (key1 == LogicalKeyboardKey.arrowUp ||
                key1 == LogicalKeyboardKey.keyW)) {
      joystickChangeDirectional(JoystickDirectionalEvent(
        directional: JoystickMoveDirectional.MOVE_UP_LEFT,
        intensity: 1.0,
        radAngle: 0.0,
      ));
    }

    if ((key1 == LogicalKeyboardKey.arrowRight ||
                key1 == LogicalKeyboardKey.keyD) &&
            (key2 == LogicalKeyboardKey.arrowUp ||
                key2 == LogicalKeyboardKey.keyW) ||
        (key2 == LogicalKeyboardKey.arrowRight ||
                key2 == LogicalKeyboardKey.keyD) &&
            (key1 == LogicalKeyboardKey.arrowUp ||
                key1 == LogicalKeyboardKey.keyW)) {
      joystickChangeDirectional(
        JoystickDirectionalEvent(
          directional: JoystickMoveDirectional.MOVE_UP_RIGHT,
          intensity: 1.0,
          radAngle: 0.0,
        ),
      );
    }
  }

  void resetDirectionalKeys() {
    _currentKeyboardKeys.clear();
  }
}
