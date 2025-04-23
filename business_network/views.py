from rest_framework.exceptions import ValidationError
from django.shortcuts import render
from django.shortcuts import get_object_or_404
from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from django.db.models import Count, Q
import base64
from django.core.files.base import ContentFile

from .models import (
    BusinessNetworkPost,
    BusinessNetworkMedia,
    BusinessNetworkPostLike,
    BusinessNetworkPostFollow,
    BusinessNetworkPostComment,
    BusinessNetworkPostTag
)
from .serializers import *
from .pagination import *

def base64ToFile(base64_data):
# Remove the prefix if it exists (e.g., "data:image/png;base64,")
    if base64_data.startswith('data:image'):
        base64_data = base64_data.split('base64,')[1]
        
    # Decode the Base64 string into bytes
    file_data = base64.b64decode(base64_data)
        
    # Create a Django ContentFile object from the bytes
    file = ContentFile(file_data)
        
    # You can create a filename, e.g., using the current timestamp or other logic
    filename = "uploaded_image.png"  # Customize as needed
        
    # Save the file to the appropriate storage (e.g., media directory)
    file.name = filename
    return file

# Post Views
class BusinessNetworkPostListCreateView(generics.ListCreateAPIView):
    queryset = BusinessNetworkPost.objects.all().order_by('-created_at')
    serializer_class = BusinessNetworkPostSerializer
    pagination_class = StandardResultsSetPagination
    permission_classes = [IsAuthenticated]
    
        
    def create(self, request, *args, **kwargs):
        images_data = request.data.pop('images', None)
        serializer = self.get_serializer(data={'title':request.data['title'], 'content':request.data['content'], 'author':request.user.id})
        
        serializer.is_valid(raise_exception=True)
        post = serializer.save()
        
            # Print or log the serializer errors
            

        if images_data:
        # Handle both list of images and single image
            if not isinstance(images_data, list):
                images_data = [images_data]
                    
            for image_data in images_data:
                try:
                    if isinstance(image_data, str) and image_data.startswith('data:image'):
                        # Process base64 image
                        image_file = base64ToFile(image_data)
                        post_media = BusinessNetworkMedia.objects.create(image=image_file)
                        post.media.add(post_media)
                except Exception as e:
                    # Log error but continue processing
                    print(f"Error processing image: {str(e)}")

        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

class BusinessNetworkPostRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    queryset = BusinessNetworkPost.objects.all()
    serializer_class = BusinessNetworkPostSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = 'slug'
    
    def perform_update(self, serializer):
        # Only allow the author to update the post
        if serializer.instance.author == self.request.user:
            serializer.save()
        else:
            return Response({"detail": "You do not have permission to edit this post."}, 
                           status=status.HTTP_403_FORBIDDEN)
    
    def perform_destroy(self, instance):
        # Only allow the author to delete the post
        if instance.author == self.request.user:
            instance.delete()
        else:
            return Response({"detail": "You do not have permission to delete this post."}, 
                           status=status.HTTP_403_FORBIDDEN)

class UserPostsListView(generics.ListAPIView):
    serializer_class = BusinessNetworkPostSerializer
    pagination_class = StandardResultsSetPagination
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user_id = self.kwargs.get('user_id')
        return BusinessNetworkPost.objects.filter(author__id=user_id).order_by('-created_at')

# Media Views
class BusinessNetworkMediaCreateView(generics.CreateAPIView):
    queryset = BusinessNetworkMedia.objects.all()
    serializer_class = BusinessNetworkMediaSerializer
    permission_classes = [IsAuthenticated]  
        
    

class BusinessNetworkMediaDestroyView(generics.DestroyAPIView):
    queryset = BusinessNetworkMedia.objects.all()
    permission_classes = [IsAuthenticated]
    
    def perform_destroy(self, instance):
        # Only allow the post author to delete media
        if instance.post.author == self.request.user:
            instance.delete()
        else:
            return Response({"detail": "You do not have permission to delete this media."}, 
                           status=status.HTTP_403_FORBIDDEN)

# Like Views
class BusinessNetworkPostLikeCreateView(generics.CreateAPIView):
    serializer_class = BusinessNetworkPostLikeSerializer
    permission_classes = [IsAuthenticated]
    
    def create(self, request, *args, **kwargs):
        post_id = kwargs.get('post_id')
        post = get_object_or_404(BusinessNetworkPost, pk=post_id)
        
        # Check if user has already liked the post
        if BusinessNetworkPostLike.objects.filter(post=post, user=request.user).exists():
            return Response(
                {"detail": "You have already liked this post."}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        like = BusinessNetworkPostLike(post=post, user=request.user)
        like.save()
        serializer = self.get_serializer(like)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class BusinessNetworkPostLikeDestroyView(generics.DestroyAPIView):
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        post_id = self.kwargs.get('post_id')
        post = get_object_or_404(BusinessNetworkPost, pk=post_id)
        like = get_object_or_404(BusinessNetworkPostLike, post=post, user=self.request.user)
        return like

# Follow Views
class BusinessNetworkPostFollowCreateView(generics.CreateAPIView):
    serializer_class = BusinessNetworkPostFollowSerializer
    permission_classes = [IsAuthenticated]
    
    def create(self, request, *args, **kwargs):
        post_id = kwargs.get('post_id')
        post = get_object_or_404(BusinessNetworkPost, pk=post_id)
        
        # Check if user already follows the post
        if BusinessNetworkPostFollow.objects.filter(post=post, user=request.user).exists():
            return Response(
                {"detail": "You are already following this post."}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        follow = BusinessNetworkPostFollow(post=post, user=request.user)
        follow.save()
        serializer = self.get_serializer(follow)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class BusinessNetworkPostFollowDestroyView(generics.DestroyAPIView):
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        post_id = self.kwargs.get('post_id')
        post = get_object_or_404(BusinessNetworkPost, pk=post_id)
        follow = get_object_or_404(BusinessNetworkPostFollow, post=post, user=self.request.user)
        return follow

# Comment Views
class BusinessNetworkPostCommentListCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkPostCommentSerializer
    pagination_class = StandardResultsSetPagination
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        post_id = self.kwargs.get('post_id')
        return BusinessNetworkPostComment.objects.filter(post__id=post_id).order_by('-created_at')
    
    def perform_create(self, serializer):
        post_id = self.kwargs.get('post_id')
        post = get_object_or_404(BusinessNetworkPost, pk=post_id)
        serializer.save(post=post, author=self.request.user)

class BusinessNetworkPostCommentRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = BusinessNetworkPostCommentSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return BusinessNetworkPostComment.objects.all()
    
    def perform_update(self, serializer):
        # Only allow comment author to update
        if serializer.instance.author == self.request.user:
            serializer.save()
        else:
            return Response({"detail": "You do not have permission to edit this comment."}, 
                           status=status.HTTP_403_FORBIDDEN)
    
    def perform_destroy(self, instance):
        # Allow comment author or post author to delete
        if instance.author == self.request.user or instance.post.author == self.request.user:
            instance.delete()
        else:
            return Response({"detail": "You do not have permission to delete this comment."}, 
                           status=status.HTTP_403_FORBIDDEN)

# Tag Views
class BusinessNetworkPostTagListCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkPostTagSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        post_id = self.kwargs.get('post_id')
        return BusinessNetworkPostTag.objects.filter(post__id=post_id)
    
    def perform_create(self, serializer):
        post_id = self.kwargs.get('post_id')
        post = get_object_or_404(BusinessNetworkPost, pk=post_id)
        # Only post author can add tags
        if post.author != self.request.user:
            return Response({"detail": "Only the post author can add tags."}, 
                          status=status.HTTP_403_FORBIDDEN)
        serializer.save(post=post)

class BusinessNetworkPostTagDestroyView(generics.DestroyAPIView):
    queryset = BusinessNetworkPostTag.objects.all()
    permission_classes = [IsAuthenticated]
    
    def perform_destroy(self, instance):
        # Only post author can delete tags
        if instance.post.author == self.request.user:
            instance.delete()
        else:
            return Response({"detail": "Only the post author can delete tags."}, 
                           status=status.HTTP_403_FORBIDDEN)

# Search and Discovery
class BusinessNetworkPostSearchView(generics.ListAPIView):
    serializer_class = BusinessNetworkPostSerializer
    pagination_class = StandardResultsSetPagination
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        query = self.request.query_params.get('q', '')
        tag = self.request.query_params.get('tag', '')
        
        queryset = BusinessNetworkPost.objects.all()
        
        if query:
            queryset = queryset.filter(
                Q(title__icontains=query) | 
                Q(content__icontains=query) |
                Q(author__username__icontains=query)
            )
        
        if tag:
            queryset = queryset.filter(post_tags__tag__icontains=tag)
        
        return queryset.order_by('-created_at').distinct()
