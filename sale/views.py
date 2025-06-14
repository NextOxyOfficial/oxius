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

def base64ToFile(base64_data):
    """Convert base64 image data to Django ContentFile"""
    # Remove the prefix if it exists (e.g., "data:image/png;base64,")
    if base64_data.startswith('data:image'):
        base64_data = base64_data.split('base64,')[1]
        
    # Decode the Base64 string into bytes
    file_data = base64.b64decode(base64_data)
        
    # Create a Django ContentFile object from the bytes
    file = ContentFile(file_data)
        
    # Create a filename with timestamp
    import uuid
    filename = f"sale_image_{uuid.uuid4().hex[:8]}.jpg"
        
    # Save the file to the appropriate storage
    file.name = filename
    return file

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
    lookup_value_converter = 'str'  # Ensure proper handling of Bangla characters in URL
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
            
        # Comprehensive search in title and description
        search = self.request.query_params.get('search')
        if search:
            from django.db.models import Q
            queryset = queryset.filter(
                Q(title__icontains=search) | Q(description__icontains=search)
            )
            
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
        logger.info(f"Creating sale post with data keys: {list(request.data.keys())}")
        
        try:
            # Extract images data before processing
            images_data = request.data.pop('images', None)
            
            # Create the serializer with the remaining data
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            
            # Create the sale post
            sale_post = serializer.save()
            logger.info(f"Sale post created successfully with ID: {sale_post.id}")
            
            # Process images if provided
            if images_data:
                # Handle both list of images and single image
                if not isinstance(images_data, list):
                    images_data = [images_data]
                
                successful_images = 0
                failed_images = 0
                
                for i, image_data in enumerate(images_data):
                    try:
                        # Skip empty images
                        if not image_data:
                            continue
                            
                        if isinstance(image_data, str) and image_data.startswith('data:image'):
                            # Process base64 image using the same pattern as business network
                            image_file = base64ToFile(image_data)
                            sale_image = SaleImage.objects.create(
                                post=sale_post,
                                image=image_file,
                                is_main=(i == 0),  # First image is main
                                order=i
                            )
                            successful_images += 1
                            logger.info(f"Successfully created image {i+1} with ID: {sale_image.id}")
                        else:
                            logger.warning(f"Skipping non-base64 image at index {i}")
                            
                    except Exception as e:
                        logger.error(f"Error processing image {i+1}: {str(e)}")
                        failed_images += 1
                        # Continue processing other images even if one fails
                
                logger.info(f"Image processing complete. Success: {successful_images}, Failed: {failed_images}")
            
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
            
        except Exception as e:
            logger.exception(f"Error in sale post creation: {str(e)}")
            return Response({"detail": f"Error creating post: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)
    
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
