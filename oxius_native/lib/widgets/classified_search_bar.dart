import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/translation_service.dart';
import '../services/classified_category_service.dart';
import 'classified_categories_grid.dart';

class ClassifiedSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final String initialValue;
  final EdgeInsetsGeometry? margin;
  final ClassifiedCategoryService? categoryService;
  final void Function(ClassifiedCategory category)? onCategoryTap;
  final bool showCategories;

  const ClassifiedSearchBar({
    super.key,
    required this.onSearch,
    this.initialValue = '',
    this.margin,
    this.categoryService,
    this.onCategoryTap,
    this.showCategories = true,
  });

  @override
  State<ClassifiedSearchBar> createState() => _ClassifiedSearchBarState();
}

class _ClassifiedSearchBarState extends State<ClassifiedSearchBar> {
  final TranslationService _ts = TranslationService();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _lastQuery = '';
  List<ClassifiedCategory> _categories = [];
  bool _loadingCategories = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue;
    _lastQuery = widget.initialValue;
    _ts.addListener(_onLangChanged);
    if (widget.showCategories && widget.categoryService != null) {
      _loadCategories();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ts.removeListener(_onLangChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onLangChanged() {
    if (!mounted) return;
    setState(() {}); // refresh placeholder translation
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_lastQuery != value) {
        _lastQuery = value;
        widget.onSearch(value.trim());
      }
      setState(() {}); // update clear icon state
    });
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
    setState(() {});
  }

  Future<void> _loadCategories() async {
    if (widget.categoryService == null) return;
    
    setState(() {
      _loadingCategories = true;
    });

    try {
      final categories = await widget.categoryService!.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _loadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCategories = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final placeholder = _ts.t('classified_search_placeholder', fallback: 'Search classifieds');
    return Container(
      margin: widget.margin ?? EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            style: GoogleFonts.roboto(fontSize: isMobile ? 13 : 14, height: 1.2),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF059669)),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: _clear,
                    )
                  : null,
              hintText: placeholder,
              hintStyle: GoogleFonts.roboto(color: Colors.grey.shade500, fontSize: isMobile ? 13 : 14),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF059669), width: 1.4),
              ),
            ),
          ),
          if (widget.showCategories && widget.categoryService != null) ...[
            const SizedBox(height: 12),
            ClassifiedCategoriesGrid(
              categories: _categories,
              isLoading: _loadingCategories,
              onTap: widget.onCategoryTap,
            ),
          ]
        ],
      ),
    );
  }
}
