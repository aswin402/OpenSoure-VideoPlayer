import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/media_provider.dart';

class SearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final String? hintText;

  const SearchBar({super.key, this.controller, this.onChanged, this.hintText});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> with TickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeProvider.primaryColor.withOpacity(0.1),
                  themeProvider.secondaryColor.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: _hasFocus
                    ? themeProvider.primaryColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: _hasFocus
                  ? [
                      BoxShadow(
                        color: themeProvider.primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Search media files...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _hasFocus
                      ? themeProvider.primaryColor
                      : Colors.white.withOpacity(0.7),
                  size: 24,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        onPressed: () {
                          _controller.clear();
                          if (widget.onChanged != null) {
                            widget.onChanged!('');
                          } else {
                            context.read<MediaProvider>().setSearchQuery('');
                          }
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                if (widget.onChanged != null) {
                  widget.onChanged!(value);
                } else {
                  context.read<MediaProvider>().setSearchQuery(value);
                }
                setState(() {});
              },
              onTap: () {
                setState(() => _hasFocus = true);
                _animationController.forward();
              },
              onEditingComplete: () {
                setState(() => _hasFocus = false);
                _animationController.reverse();
              },
              onTapOutside: (_) {
                setState(() => _hasFocus = false);
                _animationController.reverse();
                FocusScope.of(context).unfocus();
              },
            ),
          ),
        );
      },
    );
  }
}
