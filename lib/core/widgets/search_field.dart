import 'package:flutter/material.dart';

class SearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const SearchField({super.key, required this.hint, required this.onChanged});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(tooltip: 'Clear search', icon: const Icon(Icons.close_rounded), onPressed: _clear),
          ),
        ),
      ),
    );
  }
}
