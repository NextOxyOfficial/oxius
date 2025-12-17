import os
import uuid
from django.conf import settings
from django.core.files.storage import default_storage
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_file(request):
    """
    Upload a file (image or video) and return the URL
    """
    if 'file' not in request.FILES:
        return Response({
            'success': False,
            'message': 'No file provided'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    file = request.FILES['file']
    
    # Validate file size
    max_size = 100 * 1024 * 1024  # 100MB
    if file.size > max_size:
        return Response({
            'success': False,
            'message': 'File size exceeds 100MB limit'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Validate file type
    allowed_image_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
    allowed_video_types = ['video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/webm']
    allowed_types = allowed_image_types + allowed_video_types
    
    if file.content_type not in allowed_types:
        return Response({
            'success': False,
            'message': 'Invalid file type. Only images (JPG, PNG, GIF, WEBP) and videos (MP4, MOV, AVI, WEBM) are allowed'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Generate unique filename
        ext = os.path.splitext(file.name)[1]
        filename = f"{uuid.uuid4()}{ext}"
        
        # Determine folder based on file type
        if file.content_type in allowed_image_types:
            folder = 'raise_up/images'
        else:
            folder = 'raise_up/videos'
        
        # Save file
        file_path = os.path.join(folder, filename)
        saved_path = default_storage.save(file_path, file)
        
        # Generate full URL
        file_url = request.build_absolute_uri(settings.MEDIA_URL + saved_path)
        
        return Response({
            'success': True,
            'url': file_url,
            'filename': filename,
            'size': file.size,
            'type': file.content_type
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error uploading file: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
