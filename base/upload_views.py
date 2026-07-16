import os
import uuid
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

    # SECURITY: content_type and the filename extension are both client-supplied
    # and spoofable — an attacker could upload x.svg/x.html labelled image/png,
    # which then executes as active content (stored XSS). Sniff the real bytes
    # and derive the extension from a fixed allow-list, ignoring the client's.
    head = file.read(32)
    file.seek(0)
    sniffed_ext = None
    if head[:3] == b"\xff\xd8\xff":
        sniffed_ext = ".jpg"
    elif head[:8] == b"\x89PNG\r\n\x1a\n":
        sniffed_ext = ".png"
    elif head[:6] in (b"GIF87a", b"GIF89a"):
        sniffed_ext = ".gif"
    elif head[:4] == b"RIFF" and head[8:12] == b"WEBP":
        sniffed_ext = ".webp"
    elif head[4:8] == b"ftyp":
        sniffed_ext = ".mp4"  # covers mp4/mov/m4v container family
    elif head[:4] == b"\x1aE\xdf\xa3":
        sniffed_ext = ".webm"

    if sniffed_ext is None:
        return Response({
            'success': False,
            'message': 'File content does not match a supported image or video format.'
        }, status=status.HTTP_400_BAD_REQUEST)

    try:
        # Extension comes from the sniffed signature, NOT the user filename.
        filename = f"{uuid.uuid4()}{sniffed_ext}"
        
        # Determine folder based on file type
        if file.content_type in allowed_image_types:
            folder = 'raise_up/images'
        else:
            folder = 'raise_up/videos'
        
        # Save file
        file_path = os.path.join(folder, filename)
        saved_path = default_storage.save(file_path, file)
        
        # Generate full URL from the active storage backend. This works for
        # both local MEDIA_URL and Cloudflare R2/custom-domain media storage.
        file_url = request.build_absolute_uri(default_storage.url(saved_path))
        
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
