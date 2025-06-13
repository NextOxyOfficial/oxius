from rest_framework import viewsets, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from .models import Batch, Division, Subject, VideoLesson
from .serializers import BatchSerializer, DivisionSerializer, SubjectSerializer, VideoLessonSerializer


class BatchViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Batch.objects.filter(is_active=True)
    serializer_class = BatchSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'description']
    lookup_field = 'code'  # Allow lookup by code instead of ID
    
    @action(detail=True, methods=['get'])
    def divisions(self, request, code=None):
        batch = self.get_object()
        divisions = batch.divisions.filter(is_active=True)
        serializer = DivisionSerializer(divisions, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def products(self, request, code=None):
        """Fetch products associated with this batch"""
        from base.serializers import ProductSerializer
        
        batch = self.get_object()
        products = batch.products.filter(is_active=True).select_related('owner').prefetch_related('image', 'category')
        
        # Limit products for performance (can be made configurable)
        limit = request.query_params.get('limit', 10)
        try:
            limit = int(limit)
        except (ValueError, TypeError):
            limit = 10
            
        products = products[:limit]
        
        serializer = ProductSerializer(products, many=True, context={'request': request})
        return Response(serializer.data)


class DivisionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Division.objects.filter(is_active=True)
    serializer_class = DivisionSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['batches']
    search_fields = ['name', 'description']
    lookup_field = 'code'  # Allow lookup by code instead of ID
    
    @action(detail=True, methods=['get'])
    def subjects(self, request, code=None):
        division = self.get_object()
        subjects = division.subjects.filter(is_active=True)
        serializer = SubjectSerializer(subjects, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def products(self, request, code=None):
        """Fetch products associated with this division"""
        from base.serializers import ProductSerializer
        
        division = self.get_object()
        products = division.products.filter(is_active=True).select_related('owner').prefetch_related('image', 'category')
        
        # Limit products for performance (can be made configurable)
        limit = request.query_params.get('limit', 10)
        try:
            limit = int(limit)
        except (ValueError, TypeError):
            limit = 10
            
        products = products[:limit]
        
        serializer = ProductSerializer(products, many=True, context={'request': request})
        return Response(serializer.data)


class SubjectViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Subject.objects.filter(is_active=True)
    serializer_class = SubjectSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['divisions']
    search_fields = ['name', 'description']
    lookup_field = 'code'  # Allow lookup by code instead of ID
    
    @action(detail=True, methods=['get'])
    def videos(self, request, code=None):
        subject = self.get_object()
        videos = subject.videos.filter(is_active=True)
        serializer = VideoLessonSerializer(videos, many=True)
        return Response(serializer.data)


class VideoLessonViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = VideoLesson.objects.filter(is_active=True)
    serializer_class = VideoLessonSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['subject', 'lesson_name', 'is_featured']
    search_fields = ['title', 'title_bn', 'description', 'description_bn', 'lesson_name', 'lesson_name_bn']
    
    @action(detail=True, methods=['post'])
    def increment_views(self, request, pk=None):
        from .utils import track_video_view
        
        video = self.get_object()
        
        # Get IP address from request
        ip_address = request.META.get('REMOTE_ADDR')
        
        # Track the view with user details if available
        success = track_video_view(
            video_id=video.id,
            user=request.user if request.user.is_authenticated else None,
            session_key=request.session.session_key,
            ip_address=ip_address
        )
        
        if success:
            # Retrieve the latest view count (it was updated in the track_video_view function)
            video.refresh_from_db()
            return Response({'success': True, 'views': video.views_count})
        else:
            return Response({'success': False, 'message': 'Failed to track view'}, status=400)
