from django.contrib import admin
from .models import Gig, GigReview, GigFavorite, GigOrder


@admin.register(Gig)
class GigAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'category', 'price', 'status', 'views_count', 'orders_count', 'created_at')
    list_filter = ('category', 'status', 'is_featured', 'created_at')
    search_fields = ('title', 'description', 'user__first_name', 'user__last_name', 'user__email')
    readonly_fields = ('id', 'views_count', 'orders_count', 'created_at', 'updated_at')
    ordering = ('-created_at',)


@admin.register(GigReview)
class GigReviewAdmin(admin.ModelAdmin):
    list_display = ('gig', 'user', 'rating', 'created_at')
    list_filter = ('rating', 'created_at')
    search_fields = ('gig__title', 'user__first_name', 'user__last_name', 'comment')
    readonly_fields = ('id', 'created_at')
    ordering = ('-created_at',)


@admin.register(GigFavorite)
class GigFavoriteAdmin(admin.ModelAdmin):
    list_display = ('gig', 'user', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('gig__title', 'user__first_name', 'user__last_name')
    readonly_fields = ('id', 'created_at')
    ordering = ('-created_at',)


@admin.register(GigOrder)
class GigOrderAdmin(admin.ModelAdmin):
    list_display = ('id', 'gig', 'buyer', 'seller', 'price', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('gig__title', 'buyer__first_name', 'seller__first_name')
    readonly_fields = ('id', 'created_at', 'updated_at')
    ordering = ('-created_at',)
