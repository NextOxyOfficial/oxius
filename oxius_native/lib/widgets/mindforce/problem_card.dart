import 'package:flutter/material.dart';
import '../../models/mindforce_models.dart';
import '../../utils/time_utils.dart';
import '../../widgets/linkify_text.dart';

class MindForceProblemCard extends StatelessWidget {
  final MindForceProblem problem;
  final VoidCallback onTap;
  final String? currentUserId;

  const MindForceProblemCard({
    super.key,
    required this.problem,
    required this.onTap,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId != null && currentUserId == problem.userDetails.id;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and status
            Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipOval(
                    child: problem.userDetails.image != null
                        ? Image.network(
                            problem.userDetails.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildAvatarFallback();
                            },
                          )
                        : _buildAvatarFallback(),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Name and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        problem.userDetails.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        TimeUtils.formatTimeAgo(problem.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: problem.status == 'solved' 
                        ? Colors.green.shade50 
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        problem.status == 'solved' 
                            ? Icons.check_circle 
                            : Icons.help_outline,
                        size: 16,
                        color: problem.status == 'solved' 
                            ? Colors.green.shade700 
                            : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        problem.status == 'solved' ? 'Solved' : 'Active',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: problem.status == 'solved' 
                              ? Colors.green.shade700 
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Category badge
            if (problem.category != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  problem.category!.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
            
            // Title
            Text(
              problem.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            LinkifyText(
              problem.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Media preview
            if (problem.media.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: problem.media.length > 3 ? 3 : problem.media.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                problem.media[index].image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.grey.shade400,
                                    ),
                                  );
                                },
                              ),
                              if (index == 2 && problem.media.length > 3)
                                Container(
                                  color: Colors.black.withOpacity(0.6),
                                  child: Center(
                                    child: Text(
                                      '+${problem.media.length - 3}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Stats
            Row(
              children: [
                Icon(Icons.visibility, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${problem.views}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${problem.comments.length}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const Spacer(),
                
                // Payment badge
                if (problem.paymentOption == 'paid' && problem.paymentAmount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 14,
                          color: Colors.amber.shade700,
                        ),
                        Text(
                          problem.paymentAmount!.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.blue.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            color: Colors.blue.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    final name = problem.userDetails.name;
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
