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

class MiuiSegmentedItem<T> {
  const MiuiSegmentedItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class MiuiSegmentedControl<T> extends StatelessWidget {
  const MiuiSegmentedControl({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.height = 42,
  }) : super(key: key);

  final T value;
  final List<MiuiSegmentedItem<T>> items;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: HyperosTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(HyperosTheme.controlRadius),
        border: Border.all(color: HyperosTheme.border(context)),
      ),
      child: Row(
        children: items.map((item) {
          final selected = item.value == value;
          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              label: item.label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (selected) return;
                  HapticFeedback.selectionClick();
                  onChanged(item.value);
                },
                child: AnimatedContainer(
                  duration: HyperosTheme.duration(
                    context,
                    HyperosTheme.motionStandard,
                  ),
                  curve: HyperosTheme.motionCurve,
                  decoration: BoxDecoration(
                    color: selected
                        ? HyperosTheme.surface(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: selected ? HyperosTheme.shadow(context) : null,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item.icon != null) ...[
                        Icon(
                          item.icon,
                          size: 18,
                          color: selected
                              ? HyperosTheme.accent
                              : HyperosTheme.secondaryText(context),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? HyperosTheme.text(context)
                                : HyperosTheme.secondaryText(context),
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
          duration: HyperosTheme.duration(
            context,
            HyperosTheme.motionFast,
          ),
          curve: HyperosTheme.motionCurve,
          scale: _pressed ? 0.96 : 1,
          child: SizedBox(
            width: 49,
            height: 28,
            child: AnimatedContainer(
              duration: HyperosTheme.duration(
                context,
                HyperosTheme.motionStandard,
              ),
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
                duration: HyperosTheme.duration(
                  context,
                  HyperosTheme.motionStandard,
                ),
                curve: HyperosTheme.motionCurve,
                alignment:
                    widget.value ? Alignment.centerRight : Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: HyperosTheme.duration(
                    context,
                    HyperosTheme.motionFast,
                  ),
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
    this.onLongPress,
    this.enabled = true,
    this.selected = false,
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
  final VoidCallback? onLongPress;
  final bool enabled;
  final bool selected;
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
        onLongPress: widget.enabled ? widget.onLongPress : null,
        onTapDown: action == null ? null : (_) => _setPressed(true),
        onTapUp: action == null ? null : (_) => _setPressed(false),
        onTapCancel: action == null ? null : () => _setPressed(false),
        child: AnimatedContainer(
          duration: HyperosTheme.duration(
            context,
            HyperosTheme.motionFast,
          ),
          color: widget.selected
              ? HyperosTheme.accentSurface(context)
              : _pressed
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

class MiuiCheckBox extends StatelessWidget {
  const MiuiCheckBox({
    Key? key,
    required this.value,
    this.onChanged,
    this.size = 24,
  }) : super(key: key);

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      checked: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedContainer(
            duration: HyperosTheme.duration(
              context,
              HyperosTheme.motionFast,
            ),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: value ? HyperosTheme.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: value
                    ? HyperosTheme.accent
                    : HyperosTheme.secondaryText(context).withOpacity(0.62),
                width: 1.6,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
        ),
      ),
    );
  }
}

class MiuiRadioTile<T> extends StatelessWidget {
  const MiuiRadioTile({
    Key? key,
    required this.value,
    required this.groupValue,
    required this.title,
    required this.onChanged,
  }) : super(key: key);

  final T value;
  final T groupValue;
  final Widget title;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return MiuiPreferenceTile(
      title: title,
      selected: selected,
      enabled: onChanged != null,
      onTap: onChanged == null ? null : () => onChanged!(value),
      trailing: AnimatedContainer(
        duration: HyperosTheme.duration(
          context,
          HyperosTheme.motionFast,
        ),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? HyperosTheme.accent
                : HyperosTheme.secondaryText(context).withOpacity(0.6),
            width: selected ? 6 : 1.6,
          ),
        ),
      ),
    );
  }
}

class MiuiStatusView extends StatelessWidget {
  const MiuiStatusView({
    Key? key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.color = HyperosTheme.accent,
    this.compact = false,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: [title, if (description != null) description!].join('. '),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: compact ? 18 : 36,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MiuiIconContainer(
                size: compact ? 48 : 58,
                color: color,
                child: Icon(icon),
              ),
              SizedBox(height: compact ? 12 : 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HyperosTheme.text(context),
                  fontSize: compact ? 17 : 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: HyperosTheme.secondaryText(context),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MiuiFloatingControl extends StatelessWidget {
  const MiuiFloatingControl({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.large = false,
  }) : super(key: key);

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 54.0 : 46.0;
    final control = Semantics(
      button: true,
      enabled: onPressed != null,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed!();
              },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: HyperosTheme.accent,
            borderRadius: BorderRadius.circular(size * 0.36),
            boxShadow: HyperosTheme.capsuleShadow(context),
          ),
          child: Icon(icon, color: Colors.white, size: large ? 27 : 24),
        ),
      ),
    );
    return tooltip == null ? control : Tooltip(message: tooltip!, child: control);
  }
}

class MiuiActionIconButton extends StatelessWidget {
  const MiuiActionIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.danger = false,
  }) : super(key: key);

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = danger ? HyperosTheme.danger : Colors.white;
    final child = Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onPressed!();
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.38,
          child: Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: danger
                  ? HyperosTheme.danger.withOpacity(0.18)
                  : Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: foreground, size: 22),
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}

class MiuiRemoteControlBar extends StatelessWidget {
  const MiuiRemoteControlBar({
    Key? key,
    required this.actions,
    this.trailing,
  }) : super(key: key);

  final List<Widget> actions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xEE1C1C1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.10)),
          ),
          boxShadow: HyperosTheme.capsuleShadow(context),
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: HyperosTheme.springPhysics,
                child: Row(children: actions),
              ),
            ),
            if (trailing != null) ...[
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: Colors.white.withOpacity(0.14),
              ),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
