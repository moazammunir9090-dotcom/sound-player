import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'press_scale.dart';

/// A search field that grows a focus ring and reveals a clear button.
///
/// The animation is driven by focus state rather than by a controller, so it
/// also plays when the field is reached by keyboard on desktop — which is how
/// most Linux users will actually get to it.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.onChanged,
    this.hint = 'Search sounds, artists, albums',
    this.initialValue = '',
    this.autofocus = false,
  });

  final ValueChanged<String> onChanged;
  final String hint;
  final String initialValue;
  final bool autofocus;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: _focused ? palette.orange : palette.divider,
          width: _focused ? 1.6 : 1,
        ),
        boxShadow: _focused
            ? palette.lift(blur: 22, y: 8, alpha: .14)
            : const <BoxShadow>[],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          AnimatedScale(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            scale: _focused ? 1.12 : 1,
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: _focused ? palette.orange : palette.textFaint,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              // The local setState is only to show/hide the clear button; the
              // parent still receives every keystroke.
              onChanged: (value) {
                widget.onChanged(value);
                setState(() {});
              },
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: widget.hint,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.textFaint,
                ),
              ),
            ),
          ),
          // Clear button collapses rather than disappearing, so the field's
          // width never jumps.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: _controller.text.isEmpty
                ? const SizedBox(width: 12)
                : Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: PressScale(
                      scale: .85,
                      onTap: () {
                        _controller.clear();
                        widget.onChanged('');
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: palette.textFaint,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
