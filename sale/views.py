from django.shortcuts import render
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import F
import logging
import base64
from django.core.files.base import ContentFile
import hashlib
from django.utils import timezone
import datetime
from .paginations import StandardResultsSetPagination


from .models import SaleCategory, SaleChildCategory, SalePost, SaleImage, SaleBanner, SaleCondition
from .serializers import (
    SaleCategorySerializer, SaleChildCategorySerializer,
    SalePostListSerializer, SalePostDetailSerializer, SalePostCreateSerializer,
    SaleBannerSerializer, SaleConditionSerializer
)

# Set up logger
logger = logging.getLogger(__name__)

class SaleCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for listing and retrieving sale categories"""
    queryset = SaleCategory.objects.all()
    serializer_class = SaleCategorySerializer
    
    @action(detail=True, methods=['get'])
    def child_categories(self, request, pk=None):
        """Get child categories for a parent category"""
        category = self.get_object()
        child_categories = SaleChildCategory.objects.filter(parent=category)
        serializer = SaleChildCategorySerializer(child_categories, many=True)
        return Response(serializer.data)

class SaleChildCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for listing and retrieving child categories"""
    queryset = SaleChildCategory.objects.all()
    serializer_class = SaleChildCategorySerializer
    
    def get_queryset(self):
        queryset = SaleChildCategory.objects.all()
        parent_id = self.request.query_params.get('parent_id')
        
        if parent_id:
            queryset = queryset.filter(parent_id=parent_id)
            
        return queryset

class SaleBannerViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for listing and retrieving sale banners"""
    queryset = SaleBanner.objects.all().order_by('order')
    serializer_class = SaleBannerSerializer

class SaleConditionViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for listing available conditions for sale items"""
    queryset = SaleCondition.objects.filter(is_active=True).order_by('order', 'name')
    serializer_class = SaleConditionSerializer

class SalePostViewSet(viewsets.ModelViewSet):
    """ViewSet for handling sale posts"""
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    lookup_field='slug'
    pagination_class = StandardResultsSetPagination
    
    def get_queryset(self):
        if self.action in ['list', 'retrieve']:
            # For public viewing, show active posts only
            queryset = SalePost.objects.filter(status='active')
        else:
            # For other actions, filter by user
            queryset = SalePost.objects.filter(user=self.request.user)
            
        # Apply filters if provided
        seller =  self.request.query_params.get('seller')
        if seller:
            queryset = queryset.filter(user__id=seller)
        
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)
            
        child_category = self.request.query_params.get('child_category')
        if child_category:
            queryset = queryset.filter(child_category=child_category)
            
        division = self.request.query_params.get('division')
        if division:
            queryset = queryset.filter(division=division)
            
        district = self.request.query_params.get('district')
        if district:
            queryset = queryset.filter(district=district)
            
        area = self.request.query_params.get('area')
        if area:
            queryset = queryset.filter(area=area)
            
        condition = self.request.query_params.get('condition')
        if condition:
            queryset = queryset.filter(condition=condition)
            
        min_price = self.request.query_params.get('min_price')
        if min_price:
            queryset = queryset.filter(price__gte=min_price)
            
        max_price = self.request.query_params.get('max_price')
        if max_price:
            queryset = queryset.filter(price__lte=max_price)
            
        # Title search
        title = self.request.query_params.get('title')
        if title:
            queryset = queryset.filter(title__icontains=title)
            
        return queryset
    
    def get_serializer_class(self):
        if self.action == 'create' or self.action == 'update' or self.action == 'partial_update':
            return SalePostCreateSerializer
        elif self.action == 'list':
            return SalePostListSerializer
        return SalePostDetailSerializer
        
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        
        # Increment view count atomically
        SalePost.objects.filter(pk=instance.pk).update(view_count=F('view_count') + 1)
        
        # Refresh the instance to get updated view count
        instance.refresh_from_db()
        
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    def create(self, request, *args, **kwargs):
        logger.info(f"Creating sale post with data: {request.data}")
        try:
            # Handle base64 image data
            data_copy = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
            images_data = []
            
            # Debug condition values
            logger.info(f"Condition value received: {data_copy.get('condition')}")
            
            # Check if the condition exists in the database
            from .models import SaleCondition
            condition_value = data_copy.get('condition')
            if condition_value:
                condition_obj = SaleCondition.objects.filter(value=condition_value).first()
                logger.info(f"Found matching condition object: {condition_obj}")
                if not condition_obj:
                    logger.warning(f"No matching condition found in database for value: {condition_value}")
                    # List all available conditions for debugging
                    all_conditions = SaleCondition.objects.all()
                    logger.info(f"Available conditions: {list(all_conditions.values_list('value', flat=True))}")
            
            # Process base64 images if they exist
            if 'images' in data_copy:
                # Handle both list and direct access for images
                if hasattr(data_copy, 'getlist'):
                    images = data_copy.getlist('images')
                else:
                    images = data_copy['images'] if isinstance(data_copy['images'], list) else [data_copy['images']]
                
                logger.info(f"Processing {len(images)} images")
                
                for image_data in images:
                    if isinstance(image_data, str) and image_data.startswith('data:image'):
                        # It's a base64 string
                        try:
                            format, imgstr = image_data.split(';base64,')
                            ext = format.split('/')[-1]
                            data = base64.b64decode(imgstr)
                            file_name = f"sale_image_{timezone.now().strftime('%Y%m%d%H%M%S')}.{ext}"
                            file_content = ContentFile(data, name=file_name)
                            images_data.append(file_content)
                            logger.info(f"Successfully processed base64 image: {file_name}")
                        except Exception as e:
                            logger.error(f"Error processing base64 image: {str(e)}")
                    else:
                        # It's a file upload
                        images_data.append(image_data)
                        logger.info("Added non-base64 image")
                
                # Remove images from data to avoid serializer errors
                del data_copy['images']
            
            # Generate a submission hash to prevent duplicates
            user_id = request.user.id
            title = data_copy.get('title', '')
            description = data_copy.get('description', '')[:100]  # Use first 100 chars of description
            category = data_copy.get('category', '')
            
            hash_data = f"{user_id}:{title}:{description}:{category}"
            
            # Check if a post with this hash already exists (within 5 minutes)
            time_threshold = timezone.now() - datetime.timedelta(minutes=5)
            existing_post = SalePost.objects.filter(
                user=request.user,
                title=title,
                created_at__gte=time_threshold
            ).first()
            
            if existing_post:
                logger.info(f"Detected duplicate submission. Returning existing post ID: {existing_post.id}")
                response_serializer = SalePostDetailSerializer(existing_post, context={'request': request})
                return Response(response_serializer.data, status=status.HTTP_200_OK)
            
            # Add images back to data if they exist
            if images_data:
                data_copy['images'] = images_data
            
            # Ensure boolean fields are correctly parsed
            if 'negotiable' in data_copy and isinstance(data_copy['negotiable'], str):
                data_copy['negotiable'] = data_copy['negotiable'].lower() == 'true'
            
            logger.info(f"Final data being sent to serializer: {data_copy}")
            
            serializer = self.get_serializer(data=data_copy)
            
            if not serializer.is_valid():
                logger.error(f"Serializer validation errors: {serializer.errors}")
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
                
            self.perform_create(serializer)
            
            # Get the newly created post with full data
            post = SalePost.objects.get(pk=serializer.instance.id)
            response_serializer = SalePostDetailSerializer(post, context={'request': request})
            
            headers = self.get_success_headers(serializer.data)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED, headers=headers)
            
        except Exception as e:
            logger.exception(f"Error creating sale post: {str(e)}")
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def my_posts(self, request):
        """Get all posts for the current user regardless of status."""
        if not request.user.is_authenticated:
            return Response({"detail": "Authentication required"}, status=status.HTTP_401_UNAUTHORIZED)
            
        queryset = SalePost.objects.filter(user=request.user)
        
        # Apply status filter if provided
        status_param = request.query_params.get('status')
        if status_param:
            queryset = queryset.filter(status=status_param)
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = SalePostListSerializer(page, many=True, context={'request': request})
            return self.get_paginated_response(serializer.data)
            
        serializer = SalePostListSerializer(queryset, many=True, context={'request': request})
        return Response(serializer.data)
        
    @action(detail=True, methods=['post'])
    def mark_as_sold(self, request, slug=None):
        """Mark a sale post as sold."""
        post = self.get_object()
        if post.user != request.user:
            return Response(
                {"detail": "You don't have permission to mark this post as sold."},
                status=status.HTTP_403_FORBIDDEN
            )
            
        post.status = 'sold'
        post.save(update_fields=['status'])
        
        serializer = SalePostDetailSerializer(post, context={'request': request})
        return Response(serializer.data)
