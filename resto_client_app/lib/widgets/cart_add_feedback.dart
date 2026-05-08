import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';

/// Ancêtre du scaffold [HomeScreen] avec la clé placée sur l’entrée Panier
/// pour cibler l’animation.
class CartFlightTargetScope extends InheritedWidget {
  const CartFlightTargetScope({
    super.key,
    required this.cartTargetKey,
    required super.child,
  });

  final GlobalKey cartTargetKey;

  static GlobalKey? keyOf(BuildContext context) =>
      context.findAncestorWidgetOfExactType<CartFlightTargetScope>()?.cartTargetKey;

  @override
  bool updateShouldNotify(covariant CartFlightTargetScope oldWidget) =>
      cartTargetKey != oldWidget.cartTargetKey;
}

/// Animation « vol » + haptique + son court après ajout au panier.
class CartAddFeedback {
  CartAddFeedback._();

  static final AudioPlayer _audio = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  static Offset? _globalCenter(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  static Offset _fallbackCartLanding(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final insetB = mq.padding.bottom;
    const horizontalPad = 16.0;
    final inner = width - 2 * horizontalPad;
    final slot = inner / 5;
    final x = horizontalPad + slot * 1.5;
    final y = mq.size.height - insetB - 14 - 36;
    return Offset(x, y);
  }

  static Future<void> _playSound() async {
    try {
      await _audio.stop();
      await _audio.play(AssetSource('assets/sounds/cart_soft.wav'));
    } catch (_) {}
  }

  /// [context] doit avoir accès au [Overlay] et à [Provider]s (cart).
  /// [buttonContext] : contexte du widget « Commander » (centre utilisé comme départ).
  static void run({
    required BuildContext context,
    required BuildContext buttonContext,
    required Product product,
    required VoidCallback onAddToCart,
  }) {
    onAddToCart();
    HapticFeedback.mediumImpact();
    unawaited(_playSound());

    final start = _globalCenter(buttonContext);
    final key = CartFlightTargetScope.keyOf(context);
    final cartTarget =
        key != null && key.currentContext != null ? _globalCenter(key.currentContext!) : null;
    final end = cartTarget ?? _fallbackCartLanding(context);

    if (start == null) return;

    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => SizedBox.expand(
        child: _FlyParticle(
          start: start,
          end: end,
          product: product,
          screenSize: MediaQuery.sizeOf(ctx),
          onDone: entry.remove,
        ),
      ),
    );
    overlayState.insert(entry);
  }
}

class _FlyParticle extends StatefulWidget {
  const _FlyParticle({
    required this.start,
    required this.end,
    required this.product,
    required this.screenSize,
    required this.onDone,
  });

  final Offset start;
  final Offset end;
  final Product product;
  final Size screenSize;
  final VoidCallback onDone;

  @override
  State<_FlyParticle> createState() => _FlyParticleState();
}

class _FlyParticleState extends State<_FlyParticle> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _t = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        widget.onDone();
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Offset _bezier(double t, Offset p0, Offset p1, Offset p2) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  Offset _control(Offset s, Offset e) {
    final dx = ((s.dx + e.dx) / 2).clamp(-60.0, widget.screenSize.width + 60);
    final uplift = math.max(140.0, (s.dy - e.dy).abs() * 0.45 + 100);
    return Offset(dx + 24, math.min(s.dy, e.dy) - uplift);
  }

  double _scaleFor(double t) {
    if (t < 0.14) return Tween(begin: 0.35, end: 1.06).transform(t / 0.14);
    if (t > 0.78) return Tween(begin: 1.0, end: 0.32).transform((t - 0.78) / 0.22);
    return 1 + 0.06 * math.sin((t - 0.14) / 0.64 * math.pi);
  }

  Widget _bubbleChild() {
    final url = widget.product.imageUrlCacheBusted;
    if (url == null || url.isEmpty) {
      return Icon(Icons.restaurant_rounded, color: AppTheme.brandGold, size: 26);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      errorWidget: (_, _, _) =>
          Icon(Icons.restaurant_rounded, color: AppTheme.brandGold, size: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bubble = 56.0;
    final ctrl = _control(widget.start, widget.end);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final t = _t.value;
          final pos = _bezier(t, widget.start, ctrl, widget.end);
          final scale = _scaleFor(t);
          final opacity = (t < 0.92 ? 1.0 : (1 - (t - 0.92) / 0.08)).clamp(0.0, 1.0);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LandingGlowPainter(center: widget.end, progress: t),
                ),
              ),
              Positioned(
                left: pos.dx - bubble / 2,
                top: pos.dy - bubble / 2,
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: SizedBox(
                      width: bubble,
                      height: bubble,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withValues(alpha: 0.55),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.95),
                                    Colors.white.withValues(alpha: 0.78),
                                  ],
                                ),
                                border: Border.all(
                                  color: AppTheme.brandGold.withValues(alpha: 0.35),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(child: Center(child: _bubbleChild())),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Flash discret au niveau du panier à l’arrivée de la bulle.
class _LandingGlowPainter extends CustomPainter {
  _LandingGlowPainter({required this.center, required this.progress});

  final Offset center;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.78) return;
    final t = ((progress - 0.78) / 0.22).clamp(0.0, 1.0);
    final fade = math.sin(t * math.pi);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accent.withValues(alpha: 0.32 * fade),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 88));

    canvas.drawCircle(center, 74 * fade, glow);
  }

  @override
  bool shouldRepaint(covariant _LandingGlowPainter oldDelegate) =>
      oldDelegate.center != center || oldDelegate.progress != progress;
}
