from rest_framework.exceptions import ValidationError
from django.shortcuts import render
from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated,AllowAny
from django.db.models import Count, Q,OuterRef, Subquery
import base64
from django.core.files.base import ContentFile

from .models import *
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
    # permission_classes = [IsAuthenticated]
    
        
    def create(self, request, *args, **kwargs):
        images_data = request.data.pop('images', None)
        tags_data = request.data.pop('tags', None)
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
                    
        if tags_data:
            if tags_data and isinstance(tags_data, list):
                for tag_data in tags_data:
                    tag,_= BusinessNetworkPostTag.objects.get_or_create(tag=tag_data)
                    post.tags.add(tag)

        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

class BusinessNetworkPostRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    queryset = BusinessNetworkPost.objects.all()
    serializer_class = BusinessNetworkPostSerializer
    lookup_field = 'id'
    
    def get_permissions(self):
        if self.request.method == 'GET':
            return [] 
        else:
            return [IsAuthenticated()]
    
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
    # permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user_id = self.kwargs.get('user_id')
        return BusinessNetworkPost.objects.filter(author__id=user_id).order_by('-created_at')
    
class UserSavedPostListCreateView(generics.ListCreateAPIView):
    serializer_class = UserSavedPostSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return UserSavedPosts.objects.filter(user=user.id).order_by('-created_at')

    def create(self, request, *args, **kwargs):
        user = request.user
        post_id = request.data.get('post')
        serializer = self.get_serializer(data={'user': user.id, 'post': post_id})
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)


@api_view(['DELETE'])
def delete_saved_post(request, post_id):
    try:
        saved_post = UserSavedPosts.objects.get(post=post_id, user=request.user)
        saved_post.delete()
        return Response({"message": "Post deleted from saved posts."}, status=status.HTTP_200_OK)
    except UserSavedPosts.DoesNotExist:
        return Response({"error": "Post not found in saved posts."}, status=status.HTTP_404_NOT_FOUND)

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
class BusinessNetworkPostLikeCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkPostLikeSerializer
    pagination_class = StandardResultsSetPagination
    # permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        post_id = self.kwargs.get('post_id')
        if post_id:
            return BusinessNetworkPostLike.objects.filter(post_id=post_id)
        return BusinessNetworkPostLike.objects.none()
    
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
class BusinessNetworkPostFollowCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkPostFollowSerializer
    pagination_class = StandardResultsSetPagination
    # permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        post_id = self.kwargs.get('post_id')
        if post_id:
            return BusinessNetworkPostFollow.objects.filter(post_id=post_id)
        return BusinessNetworkPostFollow.objects.none()
    
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
    # permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        post_id = self.kwargs.get('post_id')
        return BusinessNetworkPostComment.objects.filter(post__id=post_id).order_by('-created_at')
    
    def perform_create(self, serializer):
        post_id = self.kwargs.get('post_id')
        post = get_object_or_404(BusinessNetworkPost, pk=post_id)
        serializer.save(post=post, author=self.request.user)
        
    def create(self, request, *args, **kwargs):
        content = request.data.get('content')
        if not content or not content.strip():
            return Response(
                {"detail": "Comment content cannot be empty."}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Fetch the post using the post_id from URL
        post_id = self.kwargs.get('post_id')
        try:
            post = get_object_or_404(BusinessNetworkPost, pk=post_id)
            post_author_id = post.author.id
            
            # Create data object with all required fields
            data = {
                'content': content,
                'post': post_id,
                'author': request.user.id
            }
            
            # Create the serializer with our prepared data
            serializer = self.get_serializer(data=data)
            
            # Validate but handle the validation ourselves
            if not serializer.is_valid():
                # If there are errors other than post and author, return them
                errors = serializer.errors.copy()
                errors.pop('post', None)
                errors.pop('author', None)
                if errors:
                    return Response(errors, status=status.HTTP_400_BAD_REQUEST)
            
            # Custom save to ensure post and author are set correctly
            comment = serializer.save(post=post, author=request.user)
            
            # Include post author ID in the response
            response_data = serializer.data
            response_data['post_author_id'] = post_author_id
            
            headers = self.get_success_headers(serializer.data)
            return Response(response_data, status=status.HTTP_201_CREATED, headers=headers)
            
        except Exception as e:
            return Response(
                {"detail": f"Error creating comment: {str(e)}"},
                status=status.HTTP_400_BAD_REQUEST
            )

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
    queryset = BusinessNetworkPostTag.objects.all()
    serializer_class = BusinessNetworkPostTagSerializer
    

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


class BusinessNetworkWorkspaceListCreateView(generics.ListCreateAPIView):
    queryset = BusinessNetworkWorkspace.objects.all()
    serializer_class = BusinessNetworkWorkspaceSerializer
    permission_classes = [IsAuthenticated]


class UserFollowCreateView(generics.CreateAPIView):
    queryset = BusinessNetworkFollowerModel.objects.all()
    serializer_class = BusinessNetworkFollowerSerializer
    permission_classes = [IsAuthenticated]
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data={"follower": request.user.id, "following": self.kwargs.get("user_id")})
            
        if not serializer.is_valid():
            print(serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

class UserUnfollowDestroyView(generics.DestroyAPIView):
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        user_id = self.kwargs.get('user_id')
        following_user = get_object_or_404(User, pk=user_id)
        follow = get_object_or_404(BusinessNetworkFollowerModel, follower=self.request.user, following=following_user)
        return follow

class UserFollowersListView(generics.ListAPIView):
    serializer_class = BusinessNetworkFollowerSerializer
    pagination_class = StandardResultsSetPagination
    
    def get_queryset(self):
        user_id = self.kwargs.get('user_id')
        return BusinessNetworkFollowerModel.objects.filter(following=user_id).order_by('-created_at')

class UserFollowingListView(generics.ListAPIView):
    serializer_class = BusinessNetworkFollowerSerializer
    pagination_class = StandardResultsSetPagination
    
    def get_queryset(self):
        user_id = self.kwargs.get('user_id')
        return BusinessNetworkFollowerModel.objects.filter(follower=user_id).order_by('-created_at')

class BusinessNetworkMediaLikeCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkMediaLikeSerializer
    
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        media_id = self.kwargs.get('media_id')
        if media_id:
            return BusinessNetworkMediaLike.objects.filter(media_id=media_id)
        return BusinessNetworkMediaLike.objects.none()
    
    def create(self, request, *args, **kwargs):
        media_id = kwargs.get('media_id')
        media = get_object_or_404(BusinessNetworkMedia, pk=media_id)
        
        # Check if user has already liked the media
        if BusinessNetworkMediaLike.objects.filter(media=media, user=request.user).exists():
            return Response(
                {"detail": "You have already liked this media."}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        like = BusinessNetworkMediaLike(media=media, user=request.user)
        like.save()
        serializer = self.get_serializer(like)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
class BusinessNetworkMediaLikeDestroyView(generics.DestroyAPIView):
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        media_id = self.kwargs.get('media_id')
        media = get_object_or_404(BusinessNetworkMedia, pk=media_id)
        like = get_object_or_404(BusinessNetworkMediaLike, media=media, user=self.request.user)
        return like
    
class BusinessNetworkMediaCommentListCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkMediaCommentSerializer
    permission_classes = [IsAuthenticated]
    #pagination_class = StandardResultsSetPagination
    
    def get_queryset(self):
        media_id = self.kwargs.get('media_id')
        return BusinessNetworkMediaComment.objects.filter(media__id=media_id).order_by('-created_at')
    
    def perform_create(self, serializer):
        media_id = self.kwargs.get('media_id')
        media = get_object_or_404(BusinessNetworkMedia, pk=media_id)
        serializer.save(media=media, author=self.request.user)
        
    def create(self, request, *args, **kwargs):
        content = request.data.get('content')
        if not content or not content.strip():
            return Response(
                {"detail": "Comment content cannot be empty."}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            media_id = self.kwargs.get('media_id')
            media = get_object_or_404(BusinessNetworkMedia, pk=media_id)
            
            data = {
                'content': content,
                'media': media_id,
                'author': request.user.id
            }
            
            serializer = self.get_serializer(data=data)
            
            if not serializer.is_valid():
                # Log all errors for debugging
                print(f"Serializer validation errors: {serializer.errors}")
                
                # Filter out media and author errors if they exist
                errors = serializer.errors.copy()
                errors.pop('media', None)
                errors.pop('author', None)
                
                # Return all original errors for better debugging
                if errors:
                    return Response({
                        "detail": "Validation errors in comment data",
                        "errors": errors,
                        "all_errors": serializer.errors  # Include all errors for debugging
                    }, status=status.HTTP_400_BAD_REQUEST)
            
            comment = serializer.save(media=media, author=request.user)
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
            
        except Exception as e:
            import traceback
            print(f"Error creating comment: {str(e)}")
            print(traceback.format_exc())  # Print stack trace for debugging
            return Response(
                {"detail": f"Error creating comment: {str(e)}"},
                status=status.HTTP_400_BAD_REQUEST
            )
        


class BusinessNetworkMediaCommentRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = BusinessNetworkMediaCommentSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return BusinessNetworkMediaComment.objects.all()
    
    def perform_update(self, serializer):
        # Only allow comment author to update
        if serializer.instance.author == self.request.user:
            serializer.save()
        else:
            return Response({"detail": "You do not have permission to edit this comment."}, 
                           status=status.HTTP_403_FORBIDDEN)
    
    def perform_destroy(self, instance):
        # Allow comment author or media author to delete
        if instance.author == self.request.user or instance.media.author == self.request.user:
            instance.delete()
        else:
            return Response({"detail": "You do not have permission to delete this comment."}, 
                           status=status.HTTP_403_FORBIDDEN)
            


class AbnAdsPanelCategoryListCreateView(generics.ListCreateAPIView):
    queryset = AbnAdsPanelCategory.objects.all()
    serializer_class = AbnAdsPanelCategorySerializer
    permission_classes = [IsAuthenticated]
    
      

class AbnAdsPanelListCreateView(generics.ListCreateAPIView):
    queryset = AbnAdsPanel.objects.all()
    serializer_class = AbnAdsPanelSerializer
    permission_classes = [IsAuthenticated]
    # pagination_class = StandardResultsSetPagination
    
    def get_queryset(self):
        queryset = AbnAdsPanel.objects.all().order_by('-created_at')
        
        # Filter by category if provided
        category = self.request.query_params.get('category', None)
        if category:
            queryset = queryset.filter(category__id=category)
        
        # Filter by gender if provided
        gender = self.request.query_params.get('gender', None)
        if gender:
            queryset = queryset.filter(gender=gender)
            
        # Filter by country if provided
        country = self.request.query_params.get('country', None)
        if country:
            queryset = queryset.filter(country=country)
            
        # Filter by ad_type if provided
        ad_type = self.request.query_params.get('ad_type', None)
        if ad_type:
            queryset = queryset.filter(ad_type=ad_type)
            
        return queryset
    
    def create(self, request, *args, **kwargs):
        
        images_data = request.data.pop('images', None)
        data = request.data
        data['user'] = request.user.id
        serializer = self.get_serializer(data=data)
                
        try:
            serializer.is_valid(raise_exception=True)
        except ValidationError as e:
            print(serializer.errors)  # Print validation errors
            raise e
        abn_ads = serializer.save()
                
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
                        abn_ads_media = AbnAdsPanelMedia.objects.create(image=image_file)
                        abn_ads.media.add(abn_ads_media)
                except Exception as e:
                    # Log error but continue processing
                    print(f"Error processing image: {str(e)}")
                            
        

        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        


class AbnAdsPanelRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    queryset = AbnAdsPanel.objects.all()
    serializer_class = AbnAdsPanelSerializer
    permission_classes = [IsAuthenticated]
    
    def perform_update(self, serializer):
        serializer.save()
    
    def perform_destroy(self, instance):
        instance.delete()

class AbnAdsPanelFilterView(generics.ListAPIView):
    serializer_class = AbnAdsPanelSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardResultsSetPagination
    
    def get_queryset(self):
        
        queryset = AbnAdsPanel.objects.all().order_by('-created_at')
        
        # Get user demographic data
        user_age = self.request.query_params.get('age', None)
        user_gender = self.request.query_params.get('gender', None)
        user_country = self.request.query_params.get('country', None)
        
        # Apply demographic filters
        if user_age:
            user_age = int(user_age)
            queryset = queryset.filter(
                models.Q(min_age__isnull=True) | models.Q(min_age__lte=user_age),
                models.Q(max_age__isnull=True) | models.Q(max_age__gte=user_age)
            )
            
        if user_gender:
            queryset = queryset.filter(
                models.Q(gender=user_gender) | models.Q(gender='other')
            )
            
        if user_country:
            queryset = queryset.filter(country=user_country)
            
        return queryset


class BusinessNetworkMindforceCategoryListView(generics.ListAPIView):
    queryset = BusinessNetworkMindforceCategory.objects.all()
    serializer_class = BusinessNetworkMindforceCategorySerializer
    permission_classes = [IsAuthenticated]


class BusinessNetworkMindForceListCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkMindforceSerializer

    def get_queryset(self):
        queryset = BusinessNetworkMindforce.objects.all().order_by('-created_at')

        # Filter by category if provided
        category = self.request.query_params.get('category', None)
        if category:
            queryset = queryset.filter(category__id=category)
            
        return queryset
            

    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsAuthenticated()]
        else:
            return [AllowAny()]
        
        
    def create(self, request, *args, **kwargs):
        images_data = request.data.pop('images', None)
        serializer = self.get_serializer(data=
                                         {'title':request.data['title'],
                                          'description':request.data['description'],
                                          'category':request.data['category'],
                                          'user':request.user.id,
                                          'payment_option':request.data['payment_option'],
                                          'payment_amount':request.data['payment_amount'],
                                          }
                                         )
                
        serializer.is_valid(raise_exception=True)
        mindforce = serializer.save()
        
        if images_data:
            # Handle both list of images and single image
            if not isinstance(images_data, list):
                images_data = [images_data]
                
            for image_data in images_data:
                try:
                    if isinstance(image_data, str) and image_data.startswith('data:image'):
                        # Process base64 image
                        image_file = base64ToFile(image_data)
                        mindforce_media = BusinessNetworkMindforceMedia.objects.create(image=image_file)
                        mindforce.media.add(mindforce_media)
                except Exception as e:
                    # Log error but continue processing
                    print(f"Error processing image: {str(e)}")
          
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    
class BusinessNetworkMindforceRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    queryset = BusinessNetworkMindforce.objects.all()
    serializer_class = BusinessNetworkMindforceSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = 'id'



class BusinessNetworkMindforceCommentsListCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkMindforceCommentSerializer
    
    def get_permissions(self):
        if self.request.method == 'GET':
            return []
        else:
            return [IsAuthenticated()]

    def get_queryset(self):
        mindforce_id = self.kwargs['mindforce_id']
        return BusinessNetworkMindforceComment.objects.filter(mindforce_problem=mindforce_id).order_by('-created_at')

    def create(self, request, *args, **kwargs):
        # Check if problem is already solved before allowing comment
        images_data = request.data.pop('images', None)
        data = request.data
        data['author'] = request.user.id
        mindforce_id = kwargs['mindforce_id']
        mindforce_problem = get_object_or_404(BusinessNetworkMindforce, id=mindforce_id)
        data['mindforce_problem'] = mindforce_id
        # If the problem is already solved, prevent commenting
        if mindforce_problem.status == 'solved':
            return Response(
                {"detail": "Cannot comment on solved problems"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create comment with initial data
        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        comment= serializer.save()
        
        # Process any media files
        if images_data:
        # Handle both list of images and single image
            if not isinstance(images_data, list):
                images_data = [images_data]
                                
            for image_data in images_data:
                try:
                    if isinstance(image_data, str) and image_data.startswith('data:image'):
                        # Process base64 image
                        image_file = base64ToFile(image_data)
                        mindforce_comment_media =BusinessNetworkMindforceCommentMedia.objects.create(image=image_file)
                        comment.media.add(mindforce_comment_medi)
                except Exception as e:
                    # Log error but continue processing
                    print(f"Error processing image: {str(e)}")
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    



class BusinessNetworkMindforceCommentDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = BusinessNetworkMindforceComment.objects.all()
    serializer_class = BusinessNetworkMindforceCommentSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = 'id'


class CheckUserFollowStatusView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request, follower_id, following_id):
        try:
            # Check if follower_id follows following_id
            follow_exists = BusinessNetworkFollowerModel.objects.filter(
                follower_id=follower_id,
                following_id=following_id
            ).exists()
            
            return Response({
                'is_following': follow_exists
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)
            
            
class TopTagsView(APIView):

    def get(self, request):
        # Access the auto-generated ManyToMany "through" table
        through_model = BusinessNetworkPost.tags.through

        # Step 1: Count how many times each tag (by tag_id) was used in posts
        tag_usage = (
            through_model.objects
            .values('businessnetworkposttag')  # FK to tag
            .annotate(count=Count('businessnetworkpost'))
            .order_by('-count')[:100]
        )

        # Step 2: Get the corresponding tag objects
        tag_ids = [item['businessnetworkposttag'] for item in tag_usage]
        tag_objects = BusinessNetworkPostTag.objects.in_bulk(tag_ids)

        # Step 3: Combine tag object + count
        results = []
        for item in tag_usage:
            tag_obj = tag_objects.get(item['businessnetworkposttag'])
            if tag_obj:
                results.append({
                    'id': tag_obj.id,
                    'tag': tag_obj.tag,
                    'count': item['count']
                })

        serializer = FrequentTagSerializer(results, many=True)
        return Response(serializer.data,status=status.HTTP_200_OK)


class BusinessNetworkNotificationListView(generics.ListAPIView):
    """List view for user notifications"""
    serializer_class = BusinessNetworkNotificationSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardResultsSetPagination
    
    def get_queryset(self):
        """Return notifications for the current user"""
        return BusinessNetworkNotification.objects.filter(recipient=self.request.user)


class BusinessNetworkNotificationReadView(generics.UpdateAPIView):
    """View to mark a notification as read"""
    serializer_class = BusinessNetworkNotificationSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = 'id'
    
    def get_queryset(self):
        """Only allow users to mark their own notifications as read"""
        return BusinessNetworkNotification.objects.filter(recipient=self.request.user)
    
    def update(self, request, *args, **kwargs):
        notification = self.get_object()
        notification.read = True
        notification.save()
        return Response({'status': 'success'}, status=status.HTTP_200_OK)


class BusinessNetworkMarkAllNotificationsReadView(generics.GenericAPIView):
    """View to mark all notifications as read"""
    permission_classes = [IsAuthenticated]
    
    def put(self, request):
        """Mark all of a user's notifications as read"""
        BusinessNetworkNotification.objects.filter(recipient=request.user, read=False).update(read=True)
        return Response({'status': 'success'}, status=status.HTTP_200_OK)


class BusinessNetworkUnreadNotificationCountView(generics.GenericAPIView):
    """View to get count of unread notifications"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """Return count of unread notifications"""
        count = BusinessNetworkNotification.objects.filter(recipient=request.user, read=False).count()
        return Response({'count': count}, status=status.HTTP_200_OK)
