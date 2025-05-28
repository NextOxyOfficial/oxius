from django.contrib import admin
from .models import Batch, Division, Subject, VideoLesson, ELearningSession, SessionActivityLog, DeviceSession, SuspiciousActivity


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


# Session Management Admin Interfaces

@admin.register(ELearningSession)
class ELearningSessionAdmin(admin.ModelAdmin):
    list_display = ('user', 'status', 'started_at', 'session_viewing_time', 'is_pro_user', 'device_fingerprint', 'ip_address')
    list_filter = ('status', 'is_pro_user', 'started_at')
    search_fields = ('user__username', 'user__email', 'device_fingerprint', 'ip_address')
    readonly_fields = ('id', 'started_at', 'last_activity', 'ended_at')
    date_hierarchy = 'started_at'
    
    fieldsets = (
        ('User Info', {
            'fields': ('user', 'is_pro_user', 'subscription_valid_until')
        }),
        ('Session Details', {
            'fields': ('id', 'session_key', 'status', 'started_at', 'last_activity', 'ended_at')
        }),
        ('Device & Location', {
            'fields': ('device_fingerprint', 'ip_address', 'user_agent')
        }),
        ('Access Tracking', {
            'fields': ('page_url', 'subject_id', 'current_video_id')
        }),
        ('Time Tracking', {
            'fields': ('total_viewing_time', 'session_viewing_time')
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user')


@admin.register(SessionActivityLog)
class SessionActivityLogAdmin(admin.ModelAdmin):
    list_display = ('session_user', 'action', 'timestamp', 'ip_address')
    list_filter = ('action', 'timestamp')
    search_fields = ('session__user__username', 'session__user__email', 'ip_address')
    readonly_fields = ('timestamp',)
    date_hierarchy = 'timestamp'
    
    def session_user(self, obj):
        return obj.session.user.username
    session_user.short_description = 'User'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('session__user')


@admin.register(DeviceSession)
class DeviceSessionAdmin(admin.ModelAdmin):
    list_display = ('user', 'device_name', 'active_sessions_count', 'max_allowed_sessions', 'is_trusted', 'last_seen')
    list_filter = ('is_trusted', 'last_seen')
    search_fields = ('user__username', 'user__email', 'device_fingerprint', 'device_name')
    readonly_fields = ('device_fingerprint', 'first_seen', 'last_seen')
    
    fieldsets = (
        ('User & Device', {
            'fields': ('user', 'device_fingerprint', 'device_name', 'browser_info')
        }),
        ('Session Management', {
            'fields': ('active_sessions_count', 'max_allowed_sessions', 'is_trusted')
        }),
        ('Timestamps', {
            'fields': ('first_seen', 'last_seen')
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user')


@admin.register(SuspiciousActivity)
class SuspiciousActivityAdmin(admin.ModelAdmin):
    list_display = ('user', 'activity_type', 'severity', 'is_resolved', 'detected_at')
    list_filter = ('activity_type', 'severity', 'is_resolved', 'detected_at')
    search_fields = ('user__username', 'user__email', 'description')
    readonly_fields = ('detected_at',)
    date_hierarchy = 'detected_at'
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('user', 'activity_type', 'severity', 'description')
        }),
        ('Evidence', {
            'fields': ('evidence', 'ip_addresses', 'device_fingerprints', 'session_ids')
        }),
        ('Resolution', {
            'fields': ('is_resolved', 'action_taken', 'resolved_at')
        }),
        ('Timestamps', {
            'fields': ('detected_at',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user')
