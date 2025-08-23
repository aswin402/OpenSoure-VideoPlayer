import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';

class SearchBar extends StatefulWidget {
  const SearchBar({super.key});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isExpanded ? 48 : 0,
              child: _isExpanded
                  ? TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search media files...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  context.read<MediaProvider>().setSearchQuery(
                                    '',
                                  );
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        context.read<MediaProvider>().setSearchQuery(value);
                        setState(() {});
                      },
                      onSubmitted: (value) {
                        if (value.isEmpty) {
                          _toggleSearch();
                        }
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          if (!_isExpanded)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
            ),
          if (_isExpanded)
            IconButton(icon: const Icon(Icons.close), onPressed: _toggleSearch),
        ],
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        _controller.clear();
        context.read<MediaProvider>().setSearchQuery('');
      }
    });
  }
}
