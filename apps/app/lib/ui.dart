import 'package:flutter/material.dart';

/// Neumorphic (Soft UI) kit. Every surface is the same matte [canvas] colour;
/// depth comes only from the dual shadow pair. Borders are never used for shape,
/// only as a non-shadow focus/state cue (shadows alone fail WCAG non-text contrast).
const canvas = Color(0xFFE5EBF2);
const ink = Color(0xFF20304B);
const muted = Color(0xFF6F7D91);
const accent = Color(0xFF138F77);
const blue = Color(0xFF2877C7);
const warn = Color(0xFFD9822B);
const danger = Color(0xFFC1443A);

const _light = Colors.white;
const _dark = Color(0x5096A6B8);

List<BoxShadow> raised([double d = 7]) => [
  BoxShadow(color: _light, offset: Offset(-d, -d), blurRadius: d * 2),
  BoxShadow(color: _dark, offset: Offset(d, d), blurRadius: d * 2),
];

List<BoxShadow> pressed([double d = 3]) => [
  BoxShadow(
    color: _dark,
    offset: Offset(d, d),
    blurRadius: d * 2.4,
    spreadRadius: -1,
  ),
  BoxShadow(
    color: _light,
    offset: Offset(-d, -d),
    blurRadius: d * 2.4,
    spreadRadius: -1,
  ),
];

bool noMotion(BuildContext c) =>
    MediaQuery.maybeOf(c)?.disableAnimations ?? false;

class SoftPanel extends StatelessWidget {
  const SoftPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.depth = 7,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double depth;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: canvas,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: raised(depth),
    ),
    child: child,
  );
}

/// Inset well - used for inputs, image frames and anything "recessed".
class SoftWell extends StatelessWidget {
  const SoftWell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: canvas,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: pressed(),
    ),
    child: child,
  );
}

/// Raised surface that visually depresses while held.
class SoftTap extends StatefulWidget {
  const SoftTap({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.semanticLabel,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final String? semanticLabel;

  @override
  State<SoftTap> createState() => _SoftTapState();
}

class _SoftTapState extends State<SoftTap> {
  bool _down = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: Focus(
        onFocusChange: (v) => setState(() => _focus = v),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: () => setState(() => _down = false),
          onTap: enabled
              ? () {
                  setState(() => _down = false);
                  widget.onTap!();
                }
              : null,
          child: AnimatedContainer(
            duration: Duration(milliseconds: noMotion(context) ? 0 : 120),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: canvas,
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: _down ? pressed() : raised(5),
              // Non-shadow focus cue.
              border: Border.all(
                color: _focus ? accent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Opacity(opacity: enabled ? 1 : 0.5, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class SoftField extends StatelessWidget {
  const SoftField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      readOnly: readOnly,
      onChanged: onChanged,
      style: const TextStyle(color: ink, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: muted),
        floatingLabelStyle: const TextStyle(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: icon == null ? null : Icon(icon, color: muted, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: canvas,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _border(Colors.transparent),
        enabledBorder: _border(Colors.transparent),
        // Non-shadow focus cue, required for WCAG.
        focusedBorder: _border(accent, 2),
      ),
    );
  }

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: BorderSide(color: c, width: w),
  );
}

/// Inputs live in a well so the recessed look survives Material's flat fill.
class SoftFieldWell extends StatelessWidget {
  const SoftFieldWell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: canvas,
      borderRadius: BorderRadius.circular(15),
      boxShadow: pressed(),
    ),
    child: child,
  );
}

class SoftDropdown<T> extends StatelessWidget {
  const SoftDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => SoftFieldWell(
    child: DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: canvas,
      borderRadius: BorderRadius.circular(16),
      icon: const Icon(Icons.expand_more_rounded, color: muted),
      style: const TextStyle(
        color: ink,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: muted),
        floatingLabelStyle: const TextStyle(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: canvas,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
      ),
      items: [
        for (final i in items)
          DropdownMenuItem(
            value: i,
            child: Text('$i', overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = accent,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          : Icon(icon ?? Icons.arrow_forward_rounded, size: 19),
      label: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFB9C6CE),
        disabledForegroundColor: Colors.white,
        elevation: 6,
        shadowColor: const Color(0x6696A6B8),
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SoftTap(
    onTap: onPressed,
    radius: 16,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: ink),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
        ],
        // Label carries the meaning; colour is never the only signal.
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class PageScroll extends StatelessWidget {
  const PageScroll({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 20, 18, 40),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: padding,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1060),
        child: child,
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.end,
    runSpacing: 14,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: ink,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              subtitle,
              style: const TextStyle(color: muted, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
      ?action,
    ],
  );
}

class StepBar extends StatelessWidget {
  const StepBar({super.key, required this.labels, required this.current});
  final List<String> labels;

  /// 0-based index of the active step.
  final int current;

  @override
  Widget build(BuildContext context) {
    // Labels sit under their circle rather than beside it: four side-by-side
    // label+circle pairs do not fit across a phone without truncating.
    return SoftPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _Connector(visible: i > 0, done: i <= current, toRight: true),
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i <= current ? accent : canvas,
                          shape: BoxShape.circle,
                          boxShadow: i <= current ? null : pressed(2),
                        ),
                        child: i < current
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: i == current ? Colors.white : muted,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                      _Connector(visible: i < labels.length - 1, done: i < current, toRight: false),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i <= current ? accent : muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.visible, required this.done, required this.toRight});
  final bool visible;
  final bool done;

  /// Which side the circle is on, so the gap sits next to the circle and the
  /// two halves between circles meet without a seam.
  final bool toRight;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 2,
      margin: toRight ? const EdgeInsets.only(right: 5) : const EdgeInsets.only(left: 5),
      color: visible ? (done ? accent : const Color(0xFFC9D2DD)) : Colors.transparent,
    ),
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.large = false});
  final bool large;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: large ? 48 : 36,
        height: large ? 48 : 36,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(large ? 16 : 12),
          boxShadow: raised(4),
        ),
        child: Icon(
          Icons.eco_rounded,
          color: Colors.white,
          size: large ? 28 : 21,
        ),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SKR TRADER',
            style: TextStyle(
              fontSize: large ? 19 : 15,
              fontWeight: FontWeight.w900,
              color: ink,
              height: 1.1,
              letterSpacing: 0.3,
            ),
          ),
          const Text(
            'GROW TOGETHER',
            style: TextStyle(
              fontSize: 8.5,
              color: accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    ],
  );
}

class FieldRow extends StatelessWidget {
  const FieldRow({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
    this.icon,
  });
  final String label;
  final String value;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: muted),
          const SizedBox(width: 9),
        ],
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(color: muted, fontSize: 12.5),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

void toast(BuildContext context, String message, {Color color = ink}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(14),
      ),
    );
}
