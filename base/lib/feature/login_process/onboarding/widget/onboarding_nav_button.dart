part of '../onboarding_view.dart';

/// Onboarding navigasyon butonu — scale + opacity basma efekti.
class OnboardingNavButton extends StatefulWidget {
  const OnboardingNavButton({
    required this.icon,
    required this.onPressed,
    this.isAccent = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isAccent;

  @override
  State<OnboardingNavButton> createState() => _OnboardingNavButtonState();
}

class _OnboardingNavButtonState extends State<OnboardingNavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacity = Tween<double>(
      begin: 1,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTapDown(TapDownDetails _) async {
    await _controller.forward();
  }

  Future<void> _handleTapUp(TapUpDetails _) async {
    await _controller.reverse();
    unawaited(HapticFeedback.lightImpact());
    widget.onPressed();
  }

  Future<void> _handleTapCancel() async {
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final iconColor = widget.isAccent ? cs.primary : cs.onSurface;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Opacity(opacity: _opacity.value, child: child),
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: widget.isAccent
                ? cs.primary.withValues(alpha: 0.15)
                : cs.onSurface.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isAccent
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(widget.icon, color: iconColor, size: 24),
        ),
      ),
    );
  }
}
