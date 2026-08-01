import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        borderRadius: BorderRadius.circular(HyperosTheme.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Shared HyperOS-style surface for dialogs that use Flutter's route-based
/// dialog API instead of RustDesk's overlay dialog manager.
class MiuiDialogPanel extends StatelessWidget {
  const MiuiDialogPanel({
    Key? key,
    required this.title,
    required this.content,
    this.icon,
    this.actions,
  }) : super(key: key);

  final Widget title;
  final Widget content;
  final Widget? icon;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 430,
          maxHeight: media.size.height * 0.86,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: HyperosTheme.surface(context),
            borderRadius: BorderRadius.circular(HyperosTheme.dialogRadius),
            border: Border.all(color: HyperosTheme.border(context)),
            boxShadow: HyperosTheme.shadow(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            physics: HyperosTheme.springPhysics,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 12)],
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          color: HyperosTheme.text(context),
                          fontSize: 22,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        child: title,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                content,
                if (actions != null) ...[const SizedBox(height: 20), actions!],
              ],
            ),
          ),
        ),
      ),
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
class MiuiSwitch extends StatefulWidget {
  const MiuiSwitch({Key? key, required this.value, this.onChanged})
      : super(key: key);

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  State<MiuiSwitch> createState() => _MiuiSwitchState();
}

class _MiuiSwitchState extends State<MiuiSwitch> {
  var _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed || !mounted) return;
    setState(() => _pressed = pressed);
  }

  void _toggle() {
    if (widget.onChanged == null) return;
    HapticFeedback.selectionClick();
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    final offColor = HyperosTheme.isDark(context)
        ? const Color(0xFF55575D)
        : const Color(0xFFD1D3D8);

    return Semantics(
      button: true,
      enabled: enabled,
      toggled: widget.value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _toggle : null,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        child: AnimatedScale(
          duration: HyperosTheme.motionFast,
          curve: HyperosTheme.motionCurve,
          scale: _pressed ? 0.96 : 1,
          child: SizedBox(
            width: 49,
            height: 28,
            child: AnimatedContainer(
              duration: HyperosTheme.motionStandard,
              curve: HyperosTheme.motionCurve,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: (widget.value ? HyperosTheme.accent : offColor)
                    .withOpacity(enabled ? 1 : 0.48),
                borderRadius: BorderRadius.circular(
                  HyperosTheme.controlRadius,
                ),
              ),
              child: AnimatedAlign(
                duration: HyperosTheme.motionStandard,
                curve: HyperosTheme.motionCurve,
                alignment:
                    widget.value ? Alignment.centerRight : Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: HyperosTheme.motionFast,
                  width: _pressed ? 22 : 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(enabled ? 1 : 0.82),
                    borderRadius: BorderRadius.circular(10),
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
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 15,
    ),
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
    if (widget.onTap != null) {
      return () {
        HapticFeedback.selectionClick();
        widget.onTap!();
      };
    }
    if (widget.switchValue != null && widget.onToggle != null) {
      return () {
        HapticFeedback.selectionClick();
        widget.onToggle!(!widget.switchValue!);
      };
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
      toggled: widget.switchValue,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: action,
        onTapDown: action == null ? null : (_) => _setPressed(true),
        onTapUp: action == null ? null : (_) => _setPressed(false),
        onTapCancel: action == null ? null : () => _setPressed(false),
        child: AnimatedContainer(
          duration: HyperosTheme.motionFast,
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
                        data: IconThemeData(color: widget.iconColor, size: 24),
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
                          fontSize: 17,
                          height: 1.22,
                          fontWeight: FontWeight.w500,
                        ),
                        child: widget.title,
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 3),
                        DefaultTextStyle.merge(
                          style: TextStyle(
                            color: HyperosTheme.secondaryText(context),
                            fontSize: 14,
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
                if (trailing != null) ...[const SizedBox(width: 10), trailing],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
