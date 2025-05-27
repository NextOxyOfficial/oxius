from rest_framework import serializers
from .models import Batch, Division, Subject, VideoLesson


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
