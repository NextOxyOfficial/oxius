import 'package:flutter/material.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';

class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final int? minLines;
  final TextStyle? style;
  final Function(String)? onSubmitted;
  final InputDecoration? decoration;

  const MentionTextField({
    super.key,
    required this.controller,
    this.hintText = 'Write a comment...',
    this.maxLines = 1,
    this.minLines,
    this.style,
    this.onSubmitted,
    this.decoration,
  });

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<BusinessNetworkUser> _suggestions = [];
  bool _isSearching = false;
  String _currentMention = '';
  int _cursorPosition = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;
    
    if (cursorPos < 0) return;

    // Find if we're typing after an @
    final beforeCursor = text.substring(0, cursorPos);
    final lastAtIndex = beforeCursor.lastIndexOf('@');
    
    if (lastAtIndex != -1) {
      // Check if there's a space between @ and cursor
      final afterAt = beforeCursor.substring(lastAtIndex + 1);
      if (!afterAt.contains(' ') && afterAt.length > 0) {
        // We're typing a mention
        _currentMention = afterAt;
        _cursorPosition = cursorPos;
        _searchUsers(afterAt);
        return;
      }
    }
    
    // Not typing a mention, hide suggestions
    _removeOverlay();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      _removeOverlay();
      return;
    }

    setState(() => _isSearching = true);

    // Search users via API
    final users = await BusinessNetworkService.searchUsers(query);
    
    // Sort: Following users first, then by name
    users.sort((a, b) {
      if (a.isFollowing && !b.isFollowing) return -1;
      if (!a.isFollowing && b.isFollowing) return 1;
      return a.name.compareTo(b.name);
    });
    
    _suggestions = users.take(10).toList(); // Limit to 10 suggestions

    setState(() => _isSearching = false);

    if (_suggestions.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -200), // Position above the text field
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final user = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 12,
                            color: Color(0xFF3B82F6),
                          ),
                        ],
                      ],
                    ),
                    subtitle: user.username != null
                        ? Text(
                            '@${user.username}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          )
                        : null,
                    trailing: user.isFollowing
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Following',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => _insertMention(user),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _insertMention(BusinessNetworkUser user) {
    final text = widget.controller.text;
    final cursorPos = _cursorPosition;
    
    // Find the @ position
    final beforeCursor = text.substring(0, cursorPos);
    final lastAtIndex = beforeCursor.lastIndexOf('@');
    
    if (lastAtIndex != -1) {
      // Replace from @ to cursor with the mention
      final beforeAt = text.substring(0, lastAtIndex);
      final afterCursor = text.substring(cursorPos);
      final mention = '@${user.name} ';
      
      widget.controller.text = beforeAt + mention + afterCursor;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: beforeAt.length + mention.length),
      );
    }
    
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _suggestions = [];
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        decoration: widget.decoration ??
            InputDecoration(
              hintText: widget.hintText,
              border: InputBorder.none,
            ),
        style: widget.style,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
