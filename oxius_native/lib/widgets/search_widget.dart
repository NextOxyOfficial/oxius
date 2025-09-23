import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class SearchWidget extends StatefulWidget {
  const SearchWidget({super.key});

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _placeholderTimer;
  int _currentPlaceholderIndex = 0;
  
  final List<String> _placeholders = [
    'Search for businesses...',
    'Find products...',
    'Discover services...',
    'Search courses...',
  ];

  @override
  void initState() {
    super.initState();
    _startPlaceholderAnimation();
  }

  void _startPlaceholderAnimation() {
    _placeholderTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_searchFocusNode.hasFocus && mounted) {
        setState(() {
          _currentPlaceholderIndex = (_currentPlaceholderIndex + 1) % _placeholders.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _placeholderTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: _searchFocusNode.hasFocus 
                  ? 'What are you looking for?' 
                  : _placeholders[_currentPlaceholderIndex],
              hintStyle: GoogleFonts.roboto(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: _searchFocusNode.hasFocus 
                    ? const Color(0xFF10B981) 
                    : Colors.grey.shade600,
                size: 24,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF10B981),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.black87,
            ),
            onChanged: (value) {
              setState(() {});
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Searching for: $value'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}