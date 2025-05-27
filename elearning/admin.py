from django.contrib import admin
from .models import Batch, Division, Subject, VideoLesson


@admin.register(Batch)
class BatchAdmin(admin.ModelAdmin):
    list_display = ('name', 'code', 'display_order', 'is_active')
    list_filter = ('is_active',)
    search_fields = ('name', 'code', 'description')
    prepopulated_fields = {'code': ('name',)}
    ordering = ('display_order', 'name')


@admin.register(Division)
class DivisionAdmin(admin.ModelAdmin):
    list_display = ('name', 'code', 'display_order', 'is_active')
    list_filter = ('is_active', 'batches')
    search_fields = ('name', 'code', 'description')
    prepopulated_fields = {'code': ('name',)}
    ordering = ('display_order', 'name')
    filter_horizontal = ('batches',)


@admin.register(Subject)
class SubjectAdmin(admin.ModelAdmin):
    list_display = ('name', 'code', 'display_order', 'is_active')
    list_filter = ('is_active', 'divisions')
    search_fields = ('name', 'code', 'description')
    prepopulated_fields = {'code': ('name',)}
    ordering = ('display_order', 'name')
    filter_horizontal = ('divisions',)


@admin.register(VideoLesson)
class VideoLessonAdmin(admin.ModelAdmin):
    list_display = ('title', 'subject', 'lesson_name', 'duration', 'is_active', 'is_featured')
    list_filter = ('is_active', 'is_featured', 'subject')
    search_fields = ('title', 'title_bn', 'description', 'lesson_name')
    readonly_fields = ('created_at', 'updated_at', 'views_count')
    fieldsets = (
        (None, {
            'fields': ('subject', 'title', 'title_bn', 'lesson_name', 'lesson_name_bn')
        }),
        ('Content Details', {
            'fields': ('description', 'description_bn', 'youtube_url', 'thumbnail_url', 'duration')
        }),
        ('Display Options', {
            'fields': ('display_order', 'is_active', 'is_featured')
        }),
        ('Statistics', {
            'fields': ('views_count', 'created_at', 'updated_at')
        }),
    )
    ordering = ('subject', 'display_order', 'title')
