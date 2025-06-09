from django.contrib import admin
from .models import Review, ReviewHelpful, ProductRatingStats


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ('user', 'product', 'rating', 'is_approved', 'is_verified_purchase', 'helpful_count', 'created_at')
    list_filter = ('rating', 'is_approved', 'is_verified_purchase', 'created_at')
    search_fields = ('user__username', 'user__email', 'product__name', 'comment')
    readonly_fields = ('helpful_count', 'created_at', 'updated_at')
    list_editable = ('is_approved',)
    ordering = ('-created_at',)
    
    fieldsets = (
        (None, {
            'fields': ('user', 'product', 'rating', 'title', 'comment')
        }),
        ('Status', {
            'fields': ('is_approved', 'is_verified_purchase', 'helpful_count')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'product')


@admin.register(ReviewHelpful)
class ReviewHelpfulAdmin(admin.ModelAdmin):
    list_display = ('user', 'review', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('user__username', 'review__comment')
    readonly_fields = ('created_at',)
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'review')


@admin.register(ProductRatingStats)
class ProductRatingStatsAdmin(admin.ModelAdmin):
    list_display = ('product', 'average_rating', 'total_reviews', 'updated_at')
    list_filter = ('updated_at',)
    search_fields = ('product__name',)
    readonly_fields = (
        'total_reviews', 'average_rating', 'rating_5_count', 'rating_4_count',
        'rating_3_count', 'rating_2_count', 'rating_1_count', 'updated_at'
    )
    
    fieldsets = (
        (None, {
            'fields': ('product',)
        }),
        ('Statistics', {
            'fields': ('total_reviews', 'average_rating', 'updated_at')
        }),
        ('Rating Distribution', {
            'fields': (
                'rating_5_count', 'rating_4_count', 'rating_3_count',
                'rating_2_count', 'rating_1_count'
            ),
            'classes': ('collapse',)
        })
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('product')
    
    actions = ['update_stats']
    
    def update_stats(self, request, queryset):
        """Action to manually update rating statistics"""
        for stats in queryset:
            stats.update_stats()
        self.message_user(request, f"Updated statistics for {queryset.count()} products.")
    update_stats.short_description = "Update rating statistics"

# Register your models here.
