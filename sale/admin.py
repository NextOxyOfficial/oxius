from django.contrib import admin
from django.utils.safestring import mark_safe
from django.utils.html import format_html
from .models import SaleCategory, SaleChildCategory, SalePost, SaleImage, SaleBanner

class SaleImageInline(admin.TabularInline):
    model = SaleImage
    extra = 0
    readonly_fields = ('image_preview',)
    
    def image_preview(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="max-height: 100px; max-width: 100px;" />', obj.image.url)
        return "No Image"
    
    image_preview.short_description = 'Preview'

@admin.register(SaleCategory)
class SaleCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'icon_preview', 'created_at')
    search_fields = ('name',)
    
    def icon_preview(self, obj):
        if obj.icon:
            return format_html('<img src="{}" style="height: 30px;" />', obj.icon.url)
        return "No Icon"
    
    icon_preview.short_description = 'Icon'

@admin.register(SaleChildCategory)
class SaleChildCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'parent', 'icon_preview', 'created_at')
    list_filter = ('parent',)
    search_fields = ('name', 'parent__name')
    
    def icon_preview(self, obj):
        if obj.icon:
            return format_html('<img src="{}" style="height: 30px;" />', obj.icon.url)
        return "No Icon"
    
    icon_preview.short_description = 'Icon'

@admin.register(SalePost)
class SalePostAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'category', 'child_category', 'price', 'negotiable', 'status', 'created_at')
    list_filter = ('status', 'category', 'child_category', 'condition', 'negotiable')
    search_fields = ('title', 'description', 'user__username', 'user__email')
    readonly_fields = ('slug', 'view_count', 'created_at', 'updated_at' )
    inlines = [SaleImageInline]
    fieldsets = (
        ('Basic Information', {
            'fields': ('title', 'slug', 'description', 'condition', 'category', 'child_category')
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
        ('Metadata', {
            'fields': ('user', 'status', 'view_count', 'created_at', 'updated_at')
        }),
    )
    
    def get_readonly_fields(self, request, obj=None):
        if obj:  # editing an existing object
            return self.readonly_fields + ('user',)
        return self.readonly_fields

@admin.register(SaleImage)
class SaleImageAdmin(admin.ModelAdmin):
    list_display = ('id', 'post', 'image_preview', 'is_main', 'order', 'created_at')
    list_filter = ('is_main', 'created_at')
    list_editable = ('is_main', 'order')
    search_fields = ('post__title',)
    
    def image_preview(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="height: 50px;" />', obj.image.url)
        return "No Image"
    
    image_preview.short_description = 'Preview'

@admin.register(SaleBanner)
class SaleBannerAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'image_preview', 'link', 'order', 'created_at')
    list_filter = ('created_at',)
    list_editable = ('title', 'link', 'order')
    search_fields = ('title',)
    
    def image_preview(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="height: 50px;" />', obj.image.url)
        return "No Image"
    
    image_preview.short_description = 'Preview'