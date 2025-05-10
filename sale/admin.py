from django.contrib import admin
from django.utils.safestring import mark_safe
from .models import SalePost, SalePostImage

class SalePostImageInline(admin.TabularInline):
    model = SalePostImage
    extra = 1
    readonly_fields = ['image_preview']
    
    def image_preview(self, obj):
        if obj.image:
            return mark_safe(f'<img src="{obj.image.url}" style="max-height: 100px; max-width: 100px;" />')
        return 'No image'
    
    image_preview.short_description = 'Preview'

@admin.register(SalePost)
class SalePostAdmin(admin.ModelAdmin):
    list_display = ['title', 'user', 'category', 'price', 'negotiable', 'status', 'created_at']
    list_filter = ['status', 'category', 'condition', 'featured', 'negotiable']
    search_fields = ['title', 'description', 'user__username', 'user__email']
    readonly_fields = ('created_at', 'updated_at', 'slug', 'view_count')  # Changed to tuple
    date_hierarchy = 'created_at'
    inlines = [SalePostImageInline]
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

@admin.register(SalePostImage)
class SalePostImageAdmin(admin.ModelAdmin):
    list_display = ['sale_post', 'is_main', 'order', 'created_at', 'image_preview']
    list_filter = ['is_main', 'created_at']
    search_fields = ['sale_post__title']
    
    def image_preview(self, obj):
        if obj.image:
            return mark_safe(f'<img src="{obj.image.url}" style="max-height: 50px; max-width: 50px;" />')
        return 'No image'
    
    image_preview.short_description = 'Preview'
