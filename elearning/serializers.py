from rest_framework import serializers
from .models import Batch, Division, Subject, VideoLesson, ElearningBanner


class ElearningBannerSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = ElearningBanner
        fields = ['id', 'title', 'image', 'link_type', 'link_url', 'display_order']

    def get_image(self, obj):
        if not obj.image:
            return ''
        try:
            url = obj.image.url
        except ValueError:
            return ''
        request = self.context.get('request')
        if request is not None and url.startswith('/'):
            return request.build_absolute_uri(url)
        return url


class BatchSerializer(serializers.ModelSerializer):
    class Meta:
        model = Batch
        fields = ['id', 'name', 'code', 'description', 'icon']


class DivisionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Division
        fields = ['id', 'name', 'code', 'description', 'icon']


class SubjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = Subject
        fields = ['id', 'name', 'code', 'description', 'icon', 'color']


class VideoLessonSerializer(serializers.ModelSerializer):
    youtube_id = serializers.SerializerMethodField()
    
    class Meta:
        model = VideoLesson
        fields = [
            'id', 'title', 'title_bn', 'description', 'description_bn', 
            'youtube_url', 'youtube_id', 'lesson_name', 'lesson_name_bn', 
            'duration', 'thumbnail_url', 'views_count', 'is_featured'
        ]
    
    def get_youtube_id(self, obj):
        return obj.get_youtube_id()
