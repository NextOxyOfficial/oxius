from django.shortcuts import render
from rest_framework import viewsets, mixins, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import F
import logging
from .models import SalePost, SalePostImage
from .serializers import (
    SalePostSerializer, 
    SalePostCreateSerializer,
    SalePostListSerializer,
    SalePostImageSerializer
)

# Set up logger
logger = logging.getLogger(__name__)

class SalePostViewSet(viewsets.ModelViewSet):
    # permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        if self.action in ['list', 'retrieve']:
            # For public viewing, show active posts only
            queryset = SalePost.objects.filter(status='active')
        else:
            # For other actions, filter by user
            queryset = SalePost.objects.filter(user=self.request.user)
            
        # Apply filters if provided
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)
            
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
            
        return queryset
    
    def get_serializer_class(self):
        if self.action == 'create':
            return SalePostCreateSerializer
        elif self.action == 'list':
            return SalePostListSerializer
        return SalePostSerializer
        
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
            # Log the keys received in the request
            logger.info(f"Request data keys: {request.data.keys()}")
            
            serializer = self.get_serializer(data=request.data)
            if not serializer.is_valid():
                logger.error(f"Serializer validation errors: {serializer.errors}")
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
                
            sale_post = serializer.save()
            logger.info(f"Sale post created with ID: {sale_post.id}")
            
            # Handle image uploads
            image_files = []
            for key in request.FILES.keys():
                if key.startswith('image_'):
                    image_files.append(request.FILES[key])
                    
            logger.info(f"Found {len(image_files)} images to upload")
            
            for i, image_file in enumerate(image_files):
                is_main = (i == 0)  # First image is the main image
                SalePostImage.objects.create(
                    sale_post=sale_post,
                    image=image_file,
                    is_main=is_main,
                    order=i
                )
            
            # Return the full post data with images
            response_serializer = SalePostSerializer(sale_post, context={'request': request})
            headers = self.get_success_headers(serializer.data)
            logger.info(f"Successfully created sale post ID: {sale_post.id}")
            return Response(response_serializer.data, status=status.HTTP_201_CREATED, headers=headers)
            
        except Exception as e:
            logger.exception(f"Error creating sale post: {str(e)}")
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def my_posts(self, request):
        """Get all posts for the current user regardless of status."""
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
    def mark_as_sold(self, request, pk=None):
        """Mark a sale post as sold."""
        post = self.get_object()
        if post.user != request.user:
            return Response(
                {"detail": "You don't have permission to mark this post as sold."},
                status=status.HTTP_403_FORBIDDEN
            )
            
        post.status = 'sold'
        post.save(update_fields=['status'])
        
        serializer = SalePostSerializer(post, context={'request': request})
        return Response(serializer.data)
