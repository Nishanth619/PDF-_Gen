import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_theme.dart';

/// Animated Feature Card with microinteractions
/// Provides scale animation on tap and optional badge
class AnimatedFeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  final bool isLarge;
  final String? helpText;

  const AnimatedFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.badge,
    this.isLarge = false,
    this.helpText,
  });

  @override
  State<AnimatedFeatureCard> createState() => _AnimatedFeatureCardState();
}

class _AnimatedFeatureCardState extends State<AnimatedFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed 
                  ? widget.color
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
              width: _isPressed ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed 
                    ? widget.color.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: _isPressed ? 20 : 10,
                offset: Offset(0, _isPressed ? 8 : 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.isLarge ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon and Badge Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon Container with gradient
                    Container(
                      padding: EdgeInsets.all(widget.isLarge ? 14 : 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withOpacity(0.15),
                            widget.color.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: widget.isLarge ? 28 : 24,
                      ),
                    ),
                    // Badge and Help
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.badge != null) _buildBadge(),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: widget.isLarge ? 16 : 12),
                // Title
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: widget.isLarge ? 18 : 15,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Description
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: widget.isLarge ? 14 : 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Arrow for large cards
                if (widget.isLarge) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          color: widget.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: widget.color,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.helpText ?? widget.description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onTap();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Try Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge() {
    Color badgeColor;
    switch (widget.badge?.toUpperCase()) {
      case 'NEW':
        badgeColor = AppTheme.successGreen;
        break;
      case 'FREE':
        badgeColor = AppTheme.accentBlue;
        break;
      case 'PRO':
        badgeColor = AppTheme.accentOrange;
        break;
      default:
        badgeColor = AppTheme.primaryStart;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        widget.badge!,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: badgeColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Gradient Button with shimmer effect
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final LinearGradient? gradient;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (gradient?.colors.first ?? AppTheme.primaryStart).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Empty State Widget with illustration placeholder
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Section Header with optional action button
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (actionText != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Text(
                actionText!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shimmer Loading Card - For list items
class ShimmerLoadingCard extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const ShimmerLoadingCard({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Shimmer Loading List - Shows multiple shimmer cards
class ShimmerLoadingList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets padding;

  const ShimmerLoadingList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return ShimmerLoadingCard(height: itemHeight);
      },
    );
  }
}

/// Shimmer Feature Card - For dashboard loading
class ShimmerFeatureCard extends StatelessWidget {
  const ShimmerFeatureCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 80,
                height: 14,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 10,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modern Settings Tile with icon and optional badge
class ModernSettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const ModernSettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                )
              : null,
          trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
      ],
    );
  }
}

/// Settings Section Card with title and items
class SettingsSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

/// Help Icon Button for Service Screen AppBars
/// Shows a bottom sheet with feature instructions
class HelpIconButton extends StatelessWidget {
  final String title;
  final String helpText;
  final IconData? icon;
  final Color? iconColor;

  const HelpIconButton({
    super.key,
    required this.title,
    required this.helpText,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: 'Help',
      onPressed: () => _showHelp(context),
    );
  }

  void _showHelp(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? Theme.of(context).colorScheme.primary;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to use',
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Help text
              Text(
                helpText,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              // Close button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Got it'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
