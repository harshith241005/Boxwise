import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.color,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: margin ?? const EdgeInsets.only(bottom: 12),
        padding: padding ??
            const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? (isDark
              ? Colors.white.withAlpha(13)
              : Colors.white),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ??
                (isDark
                    ? Colors.white.withAlpha(20)
                    : Colors.black.withAlpha(13)),
            width: 1,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withAlpha(isDark ? 51 : 38),
              color.withAlpha(isDark ? 26 : 13),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withAlpha(51),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withAlpha(153)
                    : Colors.black.withAlpha(128),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoxCard extends StatelessWidget {
  final String name;
  final String location;
  final int itemCount;
  final int capacity;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final String? imagePath;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onQrTap;

  const BoxCard({
    super.key,
    required this.name,
    required this.location,
    required this.itemCount,
    this.capacity = 0,
    required this.color,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.imagePath,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withAlpha(26) 
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor 
                : (isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isDark || isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Top Graphic Accent
                  Container(
                    height: 5,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withAlpha(128)],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: imagePath != null ? EdgeInsets.zero : const EdgeInsets.all(8),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                  image: imagePath != null && File(imagePath!).existsSync()
                                      ? DecorationImage(
                                          image: FileImage(File(imagePath!)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: imagePath == null
                                    ? Icon(Icons.inventory_2_rounded, color: color, size: 20)
                                    : null,
                              ),
                              if (onQrTap != null)
                                GestureDetector(
                                  onTap: onQrTap,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.qr_code_2_rounded, size: 16, color: Colors.grey),
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: color.withAlpha(180),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(26),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$itemCount Item${itemCount != 1 ? 's' : ''}',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
                                ),
                              ),
                              const Spacer(),
                              if (capacity > 0)
                                Text(
                                  '${((itemCount / capacity) * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey),
                                ),
                            ],
                          ),
                          if (capacity > 0) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: (itemCount / capacity).clamp(0.0, 1.0),
                                backgroundColor: color.withAlpha(20),
                                color: color,
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isFavorite)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
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

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onTap;
  final bool readOnly;
  final VoidCallback? onVoiceTap;
  final bool isListening;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search items, boxes, tags...',
    this.onTap,
    this.readOnly = false,
    this.onVoiceTap,
    this.isListening = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(13)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(20)
              : Colors.black.withAlpha(13),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppTheme.primaryColor.withAlpha(179),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onVoiceTap != null)
                IconButton(
                  icon: Icon(
                    isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: isListening ? AppTheme.errorColor : (isDark ? Colors.white.withAlpha(102) : Colors.black.withAlpha(102)),
                  ),
                  onPressed: onVoiceTap,
                ),
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white.withAlpha(102) : Colors.black.withAlpha(102),
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
            ],
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final String? lottieUrl;
  final double lottieHeight;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.lottieUrl,
    this.lottieHeight = 180,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lottieUrl != null)
              Lottie.network(
                lottieUrl!,
                height: lottieHeight,
                repeat: true,
                errorBuilder: (context, error, stackTrace) => _buildIcon(isDark),
              )
            else
              _buildIcon(isDark),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white.withAlpha(128) : Colors.black.withAlpha(128),
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

  Widget _buildIcon(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(26),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 48,
        color: AppTheme.primaryColor.withAlpha(128),
      ),
    );
  }
}

// ===== Skeleton Loading Widget =====
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 24,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: isDark
                  ? [
                      const Color(0xFF2A2A3E),
                      const Color(0xFF3A3A52),
                      const Color(0xFF2A2A3E),
                    ]
                  : [
                      Colors.grey.shade200,
                      Colors.grey.shade100,
                      Colors.grey.shade200,
                    ],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonBoxCard extends StatelessWidget {
  const SkeletonBoxCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(13) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(13),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(height: 6, borderRadius: 0),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLoader(width: 44, height: 44, borderRadius: 12),
                SizedBox(height: 12),
                SkeletonLoader(height: 16, width: 100),
                SizedBox(height: 8),
                SkeletonLoader(height: 12, width: 70),
                SizedBox(height: 12),
                SkeletonLoader(height: 14, width: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Bounce Animation Widget =====
class BounceWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const BounceWidget({super.key, required this.child, this.onTap});

  @override
  State<BounceWidget> createState() => _BounceWidgetState();
}

class _BounceWidgetState extends State<BounceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

// ===== Pulse Animation Widget =====
class PulseWidget extends StatefulWidget {
  final Widget child;

  const PulseWidget({super.key, required this.child});

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}
