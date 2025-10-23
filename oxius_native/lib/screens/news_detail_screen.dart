import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/news_models.dart';
import '../services/news_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final String slug;

  const NewsDetailScreen({
    super.key,
    required this.slug,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  NewsPost? _post;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final post = await NewsService.getPostBySlug(widget.slug);
      setState(() {
        _post = post;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Article',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF1F2937)),
            onPressed: () {
              // TODO: Implement share
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPost,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Image
                        if (_post!.image != null)
                          CachedNetworkImage(
                            imageUrl: _post!.image!,
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 300,
                              color: Colors.grey.shade200,
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 300,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported, size: 60),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tags
                              if (_post!.tags.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _post!.tags.map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53E3E).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tag.toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFFE53E3E),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 16),

                              // Title
                              Text(
                                _post!.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Meta Info
                              Row(
                                children: [
                                  // Author
                                  if (_post!.authorDetails != null) ...[
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: _post!.authorDetails!.image != null
                                          ? CachedNetworkImageProvider(
                                              _post!.authorDetails!.image!)
                                          : null,
                                      child: _post!.authorDetails!.image == null
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _post!.authorDetails!.displayName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        if (_post!.authorDetails!.profession != null)
                                          Text(
                                            _post!.authorDetails!.profession!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                  const Spacer(),
                                  // Date and Read Time
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _post!.formattedDate,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        '${_post!.readTime} min read',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Divider
                              Divider(color: Colors.grey.shade200),
                              const SizedBox(height: 24),

                              // Content
                              Html(
                                data: _post!.content,
                                style: {
                                  "body": Style(
                                    fontSize: FontSize(16),
                                    lineHeight: const LineHeight(1.6),
                                    color: const Color(0xFF374151),
                                  ),
                                  "p": Style(
                                    margin: Margins.only(bottom: 16),
                                  ),
                                  "h1": Style(
                                    fontSize: FontSize(24),
                                    fontWeight: FontWeight.bold,
                                    margin: Margins.only(top: 24, bottom: 16),
                                  ),
                                  "h2": Style(
                                    fontSize: FontSize(20),
                                    fontWeight: FontWeight.bold,
                                    margin: Margins.only(top: 20, bottom: 12),
                                  ),
                                  "h3": Style(
                                    fontSize: FontSize(18),
                                    fontWeight: FontWeight.w600,
                                    margin: Margins.only(top: 16, bottom: 8),
                                  ),
                                  "img": Style(
                                    margin: Margins.symmetric(vertical: 16),
                                  ),
                                },
                              ),

                              const SizedBox(height: 32),

                              // Comments Section
                              if (_post!.comments.isNotEmpty) ...[
                                Divider(color: Colors.grey.shade200),
                                const SizedBox(height: 24),
                                Text(
                                  'Comments (${_post!.comments.length})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _post!.comments.length,
                                  separatorBuilder: (context, index) => Divider(
                                    color: Colors.grey.shade200,
                                    height: 32,
                                  ),
                                  itemBuilder: (context, index) {
                                    final comment = _post!.comments[index];
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Colors.grey.shade300,
                                              child: const Icon(
                                                Icons.person,
                                                size: 20,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    comment.userName ?? 'Anonymous',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF1F2937),
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatCommentDate(
                                                        comment.createdAt),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 42),
                                          child: Text(
                                            comment.content,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF374151),
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _formatCommentDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
