import 'package:flutter/material.dart';

import '../hyperos_theme.dart';

/// A small set of mobile-only controls that follow Xiaomi's MIUIX visual
/// language without changing RustDesk's existing state and callbacks.
class MiuiSectionCard extends StatelessWidget {
  const MiuiSectionCard({
    Key? key,
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: HyperosTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class MiuiIconContainer extends StatelessWidget {
  const MiuiIconContainer({
    Key? key,
    required this.child,
    this.color = HyperosTheme.accent,
    this.size = 40,
  }) : super(key: key);

  final Widget child;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(HyperosTheme.isDark(context) ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(size * 0.31),
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: color, size: size * 0.55),
        child: Center(child: child),
      ),
    );
  }
}

/// A non-Material switch with the dimensions and motion used by HyperOS.
class MiuiSwitch extends StatelessWidget {
  const MiuiSwitch({
    Key? key,
    required this.value,
    this.onChanged,
  }) : super(key: key);

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final offColor = HyperosTheme.isDark(context)
        ? const Color(0xFF55575D)
        : const Color(0xFFD5D7DC);

    return Semantics(
      button: true,
      enabled: enabled,
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: SizedBox(
          width: 49,
          height: 28,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: (value ? HyperosTheme.accent : offColor)
                  .withOpacity(enabled ? 1 : 0.48),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(enabled ? 1 : 0.82),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MiuiPreferenceTile extends StatefulWidget {
  const MiuiPreferenceTile({
    Key? key,
    required this.title,
    this.leading,
    this.subtitle,
    this.value,
    this.trailing,
    this.switchValue,
    this.onToggle,
    this.onTap,
    this.enabled = true,
    this.showChevron = false,
    this.iconColor = HyperosTheme.accent,
    this.decorateLeading = false,
    this.minHeight = 56,
    this.contentPadding = const EdgeInsets.all(16),
  }) : super(key: key);

  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? value;
  final Widget? trailing;
  final bool? switchValue;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showChevron;
  final Color iconColor;
  final bool decorateLeading;
  final double minHeight;
  final EdgeInsetsGeometry contentPadding;

  @override
  State<MiuiPreferenceTile> createState() => _MiuiPreferenceTileState();
}

class _MiuiPreferenceTileState extends State<MiuiPreferenceTile> {
  var _pressed = false;

  VoidCallback? get _effectiveTap {
    if (!widget.enabled) return null;
    if (widget.onTap != null) return widget.onTap;
    if (widget.switchValue != null && widget.onToggle != null) {
      return () => widget.onToggle!(!widget.switchValue!);
    }
    return null;
  }

  void _setPressed(bool pressed) {
    if (_pressed == pressed || !mounted) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final enabledOpacity = widget.enabled ? 1.0 : 0.46;
    final action = _effectiveTap;

    Widget? trailing;
    if (widget.switchValue != null) {
      trailing = MiuiSwitch(
        value: widget.switchValue!,
        onChanged: widget.enabled ? widget.onToggle : null,
      );
    } else if (widget.trailing != null) {
      trailing = IconTheme.merge(
        data: IconThemeData(
          color: HyperosTheme.secondaryText(context),
          size: 20,
        ),
        child: widget.trailing!,
      );
    } else if (widget.showChevron) {
      trailing = Icon(
        Icons.chevron_right_rounded,
        color: HyperosTheme.secondaryText(context).withOpacity(0.62),
        size: 24,
      );
    }

    return Semantics(
      button: action != null,
      enabled: widget.enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: action,
        onTapDown: action == null ? null : (_) => _setPressed(true),
        onTapUp: action == null ? null : (_) => _setPressed(false),
        onTapCancel: action == null ? null : () => _setPressed(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _pressed
              ? HyperosTheme.accent.withOpacity(
                  HyperosTheme.isDark(context) ? 0.13 : 0.07,
                )
              : Colors.transparent,
          constraints: BoxConstraints(minHeight: widget.minHeight),
          padding: widget.contentPadding,
          child: Opacity(
            opacity: enabledOpacity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.leading != null) ...[
                  if (widget.decorateLeading)
                    MiuiIconContainer(
                      color: widget.iconColor,
                      child: widget.leading!,
                    )
                  else
                    SizedBox(
                      width: 28,
                      child: IconTheme.merge(
                        data: IconThemeData(
                          color: HyperosTheme.text(context),
                          size: 23,
                        ),
                        child: Center(child: widget.leading!),
                      ),
                    ),
                  SizedBox(width: widget.decorateLeading ? 14 : 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle.merge(
                        style: TextStyle(
                          color: HyperosTheme.text(context),
                          fontSize: 16,
                          height: 1.24,
                          fontWeight: FontWeight.w500,
                        ),
                        child: widget.title,
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        DefaultTextStyle.merge(
                          style: TextStyle(
                            color: HyperosTheme.secondaryText(context),
                            fontSize: 12.5,
                            height: 1.28,
                            fontWeight: FontWeight.w400,
                          ),
                          child: widget.subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.value != null) ...[
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.42,
                    ),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        color: HyperosTheme.secondaryText(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      child: widget.value!,
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
