import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flutter/widgets.dart';

extension GameComponentExtensions on GameComponent {
  /// Add in the game a text with animation representing damage received
  void showDamage(
    double damage, {
    TextStyle? config,
    double initVelocityTop = -5,
    double gravity = 0.5,
    double maxDownSize = 20,
    DirectionTextDamage direction = DirectionTextDamage.RANDOM,
    bool onlyUp = false,
  }) {
    if (!hasGameRef) return;
    gameRef.add(
      TextDamageComponent(
        damage.toInt().toString(),
        Vector2(
          center.x,
          y,
        ),
        config: config ??
            TextStyle(
              fontSize: 14,
              color: Color(0xFFFFFFFF),
            ),
        initVelocityTop: initVelocityTop,
        gravity: gravity,
        direction: direction,
        onlyUp: onlyUp,
        maxDownSize: maxDownSize,
      ),
    );
  }

  /// Execute the ranged attack using a component with animation
  void simpleAttackRangeByAngle({
    /// use animation facing right.
    required Future<SpriteAnimation> animation,
    required Vector2 size,

    /// Use radians angle
    required double angle,
    required double damage,
    required AttackFromEnum attackFrom,
    Vector2? destroySize,
    Future<SpriteAnimation>? animationDestroy,
    dynamic id,
    double speed = 150,
    bool withDecorationCollision = true,
    VoidCallback? onDestroy,
    CollisionConfig? collision,
    LightingConfig? lightingConfig,
    double marginFromOrigin = 16,
    Vector2? centerOffset,
  }) {
    var initPosition = (isObjectCollision()
        ? (this as ObjectCollision).rectCollision
        : this.toRect());

    Vector2 startPosition =
        initPosition.center.toVector2() + (centerOffset ?? Vector2.zero());

    double displacement =
        max(initPosition.width / 2, initPosition.height / 2) + marginFromOrigin;
    double nextX = displacement * cos(angle);
    double nextY = displacement * sin(angle);

    Vector2 diffBase = Vector2(nextX, nextY);

    startPosition.add(diffBase);
    startPosition.add(Vector2(-size.x / 2, -size.y / 2));
    gameRef.add(
      FlyingAttackObject.byAngle(
        id: id,
        position: startPosition,
        size: size,
        angle: angle,
        damage: damage,
        speed: speed,
        attackFrom: attackFrom,
        collision: collision,
        withDecorationCollision: withDecorationCollision,
        onDestroy: onDestroy,
        destroySize: destroySize,
        flyAnimation: animation,
        animationDestroy: animationDestroy,
        lightingConfig: lightingConfig,
      ),
    );
  }

  /// Execute the ranged attack using a component with animation
  void simpleAttackRangeByDirection({
    required Future<SpriteAnimation> animationRight,
    required Future<SpriteAnimation> animationLeft,
    required Future<SpriteAnimation> animationUp,
    required Future<SpriteAnimation> animationDown,
    required Vector2 size,
    required Direction direction,
    required AttackFromEnum attackFrom,
    Vector2? destroySize,
    dynamic id,
    double speed = 150,
    double damage = 1,
    bool withCollision = true,
    bool enableDiagonal = true,
    VoidCallback? onDestroy,
    CollisionConfig? collision,
    LightingConfig? lightingConfig,
    Future<SpriteAnimation>? animationDestroy,
  }) {
    Vector2 startPosition;
    Future<SpriteAnimation> attackRangeAnimation;

    Direction attackDirection = direction;

    Rect rectBase = rectConsideringCollision;

    switch (attackDirection) {
      case Direction.left:
        attackRangeAnimation = animationLeft;
        startPosition = Vector2(
          rectBase.left - size.x,
          (rectBase.top + (rectBase.height - size.y) / 2),
        );
        break;
      case Direction.right:
        attackRangeAnimation = animationRight;
        startPosition = Vector2(
          rectBase.right,
          (rectBase.top + (rectBase.height - size.y) / 2),
        );
        break;
      case Direction.up:
        attackRangeAnimation = animationUp;
        startPosition = Vector2(
          (rectBase.left + (rectBase.width - size.x) / 2),
          rectBase.top - size.y,
        );
        break;
      case Direction.down:
        attackRangeAnimation = animationDown;
        startPosition = Vector2(
          (rectBase.left + (rectBase.width - size.x) / 2),
          rectBase.bottom,
        );
        break;
      case Direction.upLeft:
        attackRangeAnimation = animationLeft;
        startPosition = Vector2(
          rectBase.left - size.x,
          (rectBase.top + (rectBase.height - size.y) / 2),
        );
        break;
      case Direction.upRight:
        attackRangeAnimation = animationRight;
        startPosition = Vector2(
          rectBase.right,
          (rectBase.top + (rectBase.height - size.y) / 2),
        );
        break;
      case Direction.downLeft:
        attackRangeAnimation = animationLeft;
        startPosition = Vector2(
          rectBase.left - size.x,
          (rectBase.top + (rectBase.height - size.y) / 2),
        );
        break;
      case Direction.downRight:
        attackRangeAnimation = animationRight;
        startPosition = Vector2(
          rectBase.right,
          (rectBase.top + (rectBase.height - size.y) / 2),
        );
        break;
    }

    gameRef.add(
      FlyingAttackObject.byDirection(
        id: id,
        direction: attackDirection,
        flyAnimation: attackRangeAnimation,
        animationDestroy: animationDestroy,
        position: startPosition,
        size: size,
        damage: damage,
        speed: speed,
        enabledDiagonal: enableDiagonal,
        attackFrom: attackFrom,
        onDestroy: onDestroy,
        destroySize: destroySize,
        withDecorationCollision: withCollision,
        collision: collision,
        lightingConfig: lightingConfig,
      ),
    );
  }

  ///Execute simple attack melee using animation
  void simpleAttackMeleeByDirection({
    Future<SpriteAnimation>? animationRight,
    Future<SpriteAnimation>? animationDown,
    Future<SpriteAnimation>? animationLeft,
    Future<SpriteAnimation>? animationUp,
    dynamic id,
    required double damage,
    required Direction direction,
    required Vector2 size,
    required AttackFromEnum attackFrom,
    bool withPush = true,
    double? sizePush,
  }) {
    Vector2 positionAttack;
    Future<SpriteAnimation>? anim;
    double pushLeft = 0;
    double pushTop = 0;
    Direction attackDirection = direction;

    Rect rectBase = rectConsideringCollision;

    switch (attackDirection) {
      case Direction.up:
        positionAttack = Vector2(
          rectBase.center.dx - size.x / 2,
          rectBase.top - size.y,
        );
        if (animationUp != null) anim = animationUp;
        pushTop = (sizePush ?? height) * -1;
        break;
      case Direction.right:
        positionAttack = Vector2(
          rectBase.right,
          rectBase.center.dy - size.y / 2,
        );
        if (animationRight != null) anim = animationRight;
        pushLeft = (sizePush ?? width);
        break;
      case Direction.down:
        positionAttack = Vector2(
          rectBase.center.dx - size.x / 2,
          rectBase.bottom,
        );
        if (animationDown != null) anim = animationDown;
        pushTop = (sizePush ?? height);
        break;
      case Direction.left:
        positionAttack = Vector2(
          rectBase.left - size.x,
          rectBase.center.dy - size.y / 2,
        );
        if (animationLeft != null) anim = animationLeft;
        pushLeft = (sizePush ?? width) * -1;
        break;
      case Direction.upLeft:
        positionAttack = Vector2(
          rectBase.left - size.x,
          rectBase.center.dy - size.y / 2,
        );
        if (animationLeft != null) anim = animationLeft;
        pushLeft = (sizePush ?? width) * -1;
        break;
      case Direction.upRight:
        positionAttack = Vector2(
          rectBase.right,
          rectBase.center.dy - size.y / 2,
        );
        if (animationRight != null) anim = animationRight;
        pushLeft = (sizePush ?? width);
        break;
      case Direction.downLeft:
        positionAttack = Vector2(
          rectBase.left - size.x,
          rectBase.center.dy - size.y / 2,
        );
        if (animationLeft != null) anim = animationLeft;
        pushLeft = (sizePush ?? width) * -1;
        break;
      case Direction.downRight:
        positionAttack = Vector2(
          rectBase.right,
          rectBase.center.dy - size.y / 2,
        );
        if (animationRight != null) anim = animationRight;
        pushLeft = (sizePush ?? width);
        break;
    }

    if (anim != null) {
      gameRef.add(
        AnimatedObjectOnce(
          animation: anim,
          position: positionAttack,
          size: size,
        ),
      );
    }

    gameRef.visibleAttackables().where((a) {
      return a.rectAttackable().overlaps(
            Rect.fromLTWH(
              positionAttack.x,
              positionAttack.y,
              size.x,
              size.y,
            ),
          );
    }).forEach(
      (enemy) {
        enemy.receiveDamage(attackFrom, damage, id);
        final rectAfterPush = enemy.position.translate(pushLeft, pushTop);
        if (withPush &&
            (enemy is ObjectCollision &&
                !(enemy as ObjectCollision)
                    .isCollision(displacement: rectAfterPush)
                    .isNotEmpty)) {
          enemy.translate(pushLeft, pushTop);
        }
      },
    );
  }

  ///Execute simple attack melee using animation
  void simpleAttackMeleeByAngle({
    /// use animation facing right.
    required Future<SpriteAnimation> animation,
    required double damage,

    /// Use radians angle
    required double angle,
    required AttackFromEnum attacker,
    dynamic id,
    required Vector2 size,
    bool withPush = true,
    double marginFromOrigin = 16,
    Vector2? centerOffset,
  }) {
    var initPosition = (isObjectCollision()
        ? (this as ObjectCollision).rectCollision
        : this.toRect());

    Vector2 startPosition =
        initPosition.center.toVector2() + (centerOffset ?? Vector2.zero());

    double displacement =
        max(initPosition.width, initPosition.height) + marginFromOrigin;
    double nextX = displacement * cos(angle);
    double nextY = displacement * sin(angle);

    Vector2 diffBase = Vector2(nextX, nextY);

    startPosition.add(diffBase);
    startPosition.add(Vector2(-size.x / 2, -size.y / 2));

    gameRef.add(
      AnimatedObjectOnce(
        animation: animation,
        position: startPosition,
        size: size,
        rotateRadAngle: angle,
      ),
    );

    Rect positionAttack = Rect.fromLTWH(
      startPosition.x,
      startPosition.y,
      size.x,
      size.y,
    );

    gameRef
        .visibleAttackables()
        .where((a) => a.rectAttackable().overlaps(positionAttack))
        .forEach((enemy) {
      enemy.receiveDamage(attacker, damage, id);
      final rectAfterPush = enemy.position.translate(diffBase.x, diffBase.y);
      if (withPush &&
          (enemy is ObjectCollision &&
              !(enemy as ObjectCollision)
                  .isCollision(displacement: rectAfterPush)
                  .isNotEmpty)) {
        enemy.translate(diffBase.x, diffBase.y);
      }
    });
  }

  Direction getComponentDirectionFromMe(GameComponent? comp) {
    Rect rectToMove = getRectAndCollision(this);
    double centerXPlayer = comp?.center.x ?? 0;
    double centerYPlayer = comp?.center.y ?? 0;

    double centerYEnemy = rectToMove.center.dy;
    double centerXEnemy = rectToMove.center.dx;

    double diffX = centerXEnemy - centerXPlayer;
    double diffY = centerYEnemy - centerYPlayer;

    if (diffX.abs() > diffY.abs()) {
      return diffX > 0 ? Direction.left : Direction.right;
    } else {
      return diffY > 0 ? Direction.up : Direction.down;
    }
  }

  double get top => position.y;
  double get bottom => absolutePositionOfAnchor(Anchor.bottomRight).y;
  double get left => position.x;
  double get right => absolutePositionOfAnchor(Anchor.bottomRight).x;

  bool overlaps(Rect other) {
    if (right <= other.left || other.right <= left) return false;
    if (bottom <= other.top || other.bottom <= top) return false;
    return true;
  }

  /// Gets rect used how base in calculations considering collision
  Rect get rectConsideringCollision {
    return (this.isObjectCollision()
        ? (this as ObjectCollision).rectCollision
        : toRect());
  }

  /// Method that checks if this component contain collisions
  bool isObjectCollision() {
    return (this is ObjectCollision &&
        (this as ObjectCollision).containCollision());
  }

  void applyBleedingPixel({
    required Vector2 position,
    required Vector2 size,
    double factor = 0.04,
    double offsetX = 0,
    double offsetY = 0,
    bool calculatePosition = false,
  }) {
    double bleedingPixel = max(size.x, size.y) * factor;
    if (bleedingPixel > 2) {
      bleedingPixel = 2;
    }
    Vector2 baseP = position;
    if (calculatePosition) {
      baseP = Vector2(position.x * size.x, position.y * size.y);
    }
    this.position = Vector2(
      baseP.x - (baseP.x % 2 == 0 ? (bleedingPixel / 2) : 0) + offsetX,
      baseP.y - (baseP.y % 2 == 0 ? (bleedingPixel / 2) : 0) + offsetY,
    );
    this.size = Vector2(
      size.x + (baseP.x % 2 == 0 ? bleedingPixel : 0),
      size.y + (baseP.y % 2 == 0 ? bleedingPixel : 0),
    );
  }

  Direction? directionThePlayerIsIn() {
    Player? player = this.gameRef.player;
    if (player == null) return null;
    var diffX = center.x - player.center.x;
    var diffPositiveX = diffX < 0 ? diffX *= -1 : diffX;
    var diffY = center.y - player.center.y;
    var diffPositiveY = diffY < 0 ? diffY *= -1 : diffY;

    if (diffPositiveX > diffPositiveY) {
      if (player.center.x > center.y) {
        return Direction.right;
      } else if (player.center.x < center.y) {
        return Direction.left;
      }
    } else {
      if (player.center.y > center.x) {
        return Direction.down;
      } else if (player.center.y < position.x) {
        return Direction.up;
      }
    }

    return Direction.left;
  }

  /// Used to generate numbers to create your animations or anythings
  ValueGeneratorComponent generateValues(
    Duration duration, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.linear,
    bool autoStart = true,
    VoidCallback? onFinish,
    ValueChanged<double>? onChange,
  }) {
    final valueGenerator = ValueGeneratorComponent(duration,
        end: end,
        begin: begin,
        curve: curve,
        onFinish: onFinish,
        onChange: onChange,
        autoStart: autoStart);
    add(valueGenerator);
    return valueGenerator;
  }

  /// Used to add particles in your component.
  void addParticle(
    Particle particle, {
    Vector2? position,
    Vector2? size,
    Vector2? scale,
    double? angle,
    Anchor? anchor,
    int? priority,
  }) {
    this.add(
      ParticleSystemComponent(
        particle: particle,
        position: position,
        size: size,
        scale: scale,
        angle: angle,
        anchor: anchor,
        priority: priority,
      ),
    );
  }
}
