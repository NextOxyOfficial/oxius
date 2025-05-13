from django.contrib import admin
from django.utils.safestring import mark_safe
from .models import *
from django.utils.html import format_html



@admin.register(SalePost)
class SalePostAdmin(admin.ModelAdmin):
    list_display = ['title', 'user', 'category', 'price', 'negotiable', 'status', 'created_at']
    list_filter = ['status', 'category', 'condition', 'featured', 'negotiable']
    search_fields = ['title', 'description', 'user__username', 'user__email']
    readonly_fields = ('created_at', 'updated_at', 'slug', 'view_count')  # Changed to tuple
    date_hierarchy = 'created_at'
    fieldsets = (
        ('Basic Information', {
            'fields': ('title', 'slug', 'description', 'condition', 'category')
        }),
        ('Price Information', {
            'fields': ('price', 'negotiable')
        }),
        ('Location Information', {
            'fields': ('division', 'district', 'area', 'detailed_address')
        }),
        ('Contact Information', {
            'fields': ('phone', 'email')
        }),
        ('Property Fields', {
            'fields': ('property_type', 'size', 'unit', 'bedrooms', 'bathrooms', 'amenities'),
            'classes': ('collapse',),
        }),
        ('Vehicle Fields', {
            'fields': ('vehicle_type', 'make', 'model', 'year', 'mileage', 'fuel_type', 'transmission', 'registration_year'),
            'classes': ('collapse',),
        }),
        ('Electronics Fields', {
            'fields': ('electronics_type', 'brand', 'age_value', 'age_unit', 'warranty'),
            'classes': ('collapse',),
        }),
        ('Other Fields', {
            'fields': ('item_type', 'item_quality'),
            'classes': ('collapse',),
        }),
        ('Metadata', {
            'fields': ('user', 'status', 'featured', 'view_count', 'created_at', 'updated_at', 'expires_at')
        }),
    )
    
    def get_readonly_fields(self, request, obj=None):
        if obj:  # editing an existing object
            return self.readonly_fields + ('user',)  # This works with tuples
        return self.readonly_fields

admin.site.register(SalePostImage)

    
# Register For Sale models
class ForSaleCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'icon_display')
    
    def icon_display(self, obj):
        if obj.icon:
            return format_html('<img src="{}" style="height: 30px;" />', obj.icon.url)
        return "No Icon"
    
    icon_display.short_description = 'Icon'

admin.site.register(ForSaleCategory, ForSaleCategoryAdmin)

admin.site.register(ForSaleSubCategory)

class ForSaleBannerAdmin(admin.ModelAdmin):
    list_display = ('title', 'image_display', 'link')
    
    def image_display(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="height: 50px;" />', obj.image.url)
        return "No Image"
    
    image_display.short_description = 'Banner Image'

admin.site.register(ForSaleBanner, ForSaleBannerAdmin)