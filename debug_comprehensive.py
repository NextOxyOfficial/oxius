#!/usr/bin/env python
"""
Comprehensive test to debug why user's posts aren't appearing at the top
"""
import os
import sys
import django
from datetime import datetime

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from business_network.models import BusinessNetworkPost, BusinessNetworkFollowerModel
from base.models import User
from django.db.models import Case, When, IntegerField, Value, Subquery, Q

def debug_feed_issue():
    print("🔍 DEBUGGING FEED ISSUE")
    print("=" * 60)
    
    # Check if there are any users and posts
    total_users = User.objects.count()
    total_posts = BusinessNetworkPost.objects.count()
    
    print(f"📊 Database Stats:")
    print(f"   Total users: {total_users}")
    print(f"   Total posts: {total_posts}")
    
    if total_users == 0:
        print("❌ No users found in database!")
        return
    
    if total_posts == 0:
        print("❌ No posts found in database!")
        return
    
    # Find users who have posts
    users_with_posts = User.objects.filter(businessnetworkpost__isnull=False).distinct()
    print(f"   Users with posts: {users_with_posts.count()}")
    
    if users_with_posts.count() == 0:
        print("❌ No users have posts!")
        return
    
    # Test with the first user who has posts
    user = users_with_posts.first()
    print(f"\n👤 Testing with user: {user.username} (ID: {user.id})")
    print(f"   Email: {user.email}")
    print(f"   Authentication status: {'Authenticated' if user else 'Not authenticated'}")
    
    # Check user's posts
    user_posts = BusinessNetworkPost.objects.filter(author=user).order_by('-created_at')
    print(f"\n📝 User's posts: {user_posts.count()}")
    
    if user_posts.count() > 0:
        latest_post = user_posts.first()
        print(f"   Latest post: '{latest_post.title}' (ID: {latest_post.id})")
        print(f"   Created at: {latest_post.created_at}")
    
    # Simulate the exact feed logic from views.py
    print(f"\n🔧 Testing feed prioritization logic...")
    
    # Build all the subqueries exactly like in views.py
    users_i_follow_subquery = BusinessNetworkFollowerModel.objects.filter(
        follower=user
    ).values('following_id')
    
    my_followers_subquery = BusinessNetworkFollowerModel.objects.filter(
        following=user
    ).values('follower_id')
    
    followers_of_my_followings_subquery = BusinessNetworkFollowerModel.objects.filter(
        following_id__in=Subquery(users_i_follow_subquery)
    ).values('follower_id')
    
    followings_of_my_followings_subquery = BusinessNetworkFollowerModel.objects.filter(
        follower_id__in=Subquery(users_i_follow_subquery)
    ).values('following_id')
    
    # Build nearby users subquery
    nearby_users_conditions = Q()
    if user.city:
        nearby_users_conditions |= Q(city__iexact=user.city)
        if user.state and user.state != user.city:
            nearby_users_conditions |= Q(state__iexact=user.state)
    
    nearby_users_subquery = User.objects.filter(
        nearby_users_conditions
    ).exclude(id=user.id).values('id')
    
    print(f"   Users I follow: {list(users_i_follow_subquery)}")
    print(f"   My followers: {list(my_followers_subquery)}")
    print(f"   Nearby users: {list(nearby_users_subquery)}")
    
    # Create the exact queryset from views.py
    queryset = BusinessNetworkPost.objects.annotate(
        priority=Case(
            # Priority 1: User's own posts (highest priority)
            When(author=user, then=Value(1)),
            # Priority 2: Posts from users I'm following
            When(author_id__in=Subquery(users_i_follow_subquery), then=Value(2)),
            # Priority 3: Posts from followers of users I'm following
            When(author_id__in=Subquery(followers_of_my_followings_subquery), then=Value(3)),
            # Priority 4: Posts from users who are following me
            When(author_id__in=Subquery(my_followers_subquery), then=Value(4)),
            # Priority 5: Posts from users that my followings are following
            When(author_id__in=Subquery(followings_of_my_followings_subquery), then=Value(5)),
            # Priority 6: Posts from users in nearby cities
            When(author_id__in=Subquery(nearby_users_subquery), then=Value(6)),
            # Priority 7: Other posts (lowest priority)
            default=Value(7),
            output_field=IntegerField()
        )
    ).select_related('author').order_by('priority', '-created_at')
    
    # Get the first 10 posts
    first_10_posts = queryset[:10]
    
    print(f"\n📋 First 10 posts in prioritized feed:")
    print("-" * 60)
    
    user_posts_in_top_10 = 0
    for i, post in enumerate(first_10_posts, 1):
        is_user_post = post.author.id == user.id
        marker = " ⭐ YOUR POST" if is_user_post else ""
        priority_marker = f"P{post.priority}"
        
        print(f"{i:2d}. {priority_marker} | {post.author.username:15} | {post.title[:35]:35} | {post.created_at.strftime('%m-%d %H:%M')}{marker}")
        
        if is_user_post:
            user_posts_in_top_10 += 1
    
    print("-" * 60)
    print(f"✅ User's posts in top 10: {user_posts_in_top_10}")
    
    # Check if user's most recent post is at the top
    if first_10_posts and user_posts.exists():
        first_post = first_10_posts[0]
        latest_user_post = user_posts.first()
        
        if first_post.author.id == user.id and first_post.id == latest_user_post.id:
            print("✅ SUCCESS: User's most recent post is at the top!")
        else:
            print("❌ ISSUE: User's most recent post is NOT at the top")
            print(f"   First post is by: {first_post.author.username} (Priority {first_post.priority})")
            print(f"   User's latest post priority should be 1, actual: {queryset.filter(id=latest_user_post.id).first().priority if queryset.filter(id=latest_user_post.id).exists() else 'Not found'}")
    
    # Check raw SQL
    print(f"\n🔍 SQL Query being generated:")
    print(f"   {str(queryset.query)[:100]}...")
    
    print("\n" + "=" * 60)

if __name__ == "__main__":
    debug_feed_issue()
