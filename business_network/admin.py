from django.contrib import admin
from .models import *
# Register your models here.

admin.site.register(BusinessNetworkMedia)
admin.site.register(BusinessNetworkPost)
admin.site.register(BusinessNetworkPostComment)
admin.site.register(BusinessNetworkPostLike)
admin.site.register(BusinessNetworkPostFollow)
admin.site.register(BusinessNetworkPostTag)
admin.site.register(BusinessNetworkWorkspace)
admin.site.register(BusinessNetworkFollowerModel)
admin.site.register(BusinessNetworkMediaLike)
admin.site.register(BusinessNetworkMediaComment)
admin.site.register(BusinessNetworkMindforce)
admin.site.register(BusinessNetworkMindforceCategory)
admin.site.register(BusinessNetworkMindforceMedia)
admin.site.register(BusinessNetworkMindforceComment)
admin.site.register(UserSavedPosts)
admin.site.register(AbnAdsPanelCategory)
admin.site.register(AbnAdsPanel)
admin.site.register(AbnAdsPanelMedia)

# Hidden Posts and Reports Admin
@admin.register(HiddenPost)
class HiddenPostAdmin(admin.ModelAdmin):
    list_display = ['user', 'post', 'created_at']
    list_filter = ['created_at']
    search_fields = ['user__username', 'post__id']
    ordering = ['-created_at']

@admin.register(PostReport)
class PostReportAdmin(admin.ModelAdmin):
    list_display = ['user', 'post', 'reason', 'status', 'created_at']
    list_filter = ['reason', 'status', 'created_at']
    search_fields = ['user__username', 'post__id', 'description']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at']
    
    fieldsets = (
        ('Report Information', {
            'fields': ('user', 'post', 'reason', 'description')
        }),
        ('Status', {
            'fields': ('status',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['mark_as_reviewed', 'mark_as_resolved', 'mark_as_dismissed']
    
    def mark_as_reviewed(self, request, queryset):
        updated = queryset.update(status='reviewed')
        self.message_user(request, f'{updated} reports marked as reviewed.')
    mark_as_reviewed.short_description = "Mark as reviewed"
    
    def mark_as_resolved(self, request, queryset):
        updated = queryset.update(status='resolved')
        self.message_user(request, f'{updated} reports marked as resolved.')
    mark_as_resolved.short_description = "Mark as resolved"
    
    def mark_as_dismissed(self, request, queryset):
        updated = queryset.update(status='dismissed')
        self.message_user(request, f'{updated} reports dismissed.')
    mark_as_dismissed.short_description = "Dismiss reports"

# Gold Sponsors Admin
@admin.register(SponsorshipPackage)
class SponsorshipPackageAdmin(admin.ModelAdmin):
    list_display = ['name', 'price', 'duration_months', 'is_active', 'created_at']
    list_filter = ['is_active', 'duration_months']
    search_fields = ['name', 'description']
    ordering = ['duration_months', 'price']
    
    fieldsets = (
        ('Package Information', {
            'fields': ('name', 'description', 'price', 'duration_months')
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
    )

class GoldSponsorBannerInline(admin.TabularInline):
    model = GoldSponsorBanner
    extra = 1
    fields = ['title', 'image', 'link_url', 'order', 'is_active']

@admin.register(GoldSponsor)
class GoldSponsorAdmin(admin.ModelAdmin):
    list_display = ['business_name', 'user', 'contact_email', 'package', 'status', 'views', 'is_featured', 'start_date', 'end_date']
    list_filter = ['status', 'is_featured', 'package', 'created_at', 'user']
    search_fields = ['business_name', 'contact_email', 'phone_number', 'user__username', 'user__email']
    ordering = ['-created_at']
    readonly_fields = ['slug', 'views', 'created_at', 'updated_at']
    inlines = [GoldSponsorBannerInline]
    
    fieldsets = (
        ('Owner Information', {
            'fields': ('user',)
        }),
        ('Business Information', {
            'fields': ('business_name', 'business_description', 'slug', 'logo')
        }),
        ('Contact Information', {
            'fields': ('contact_email', 'phone_number', 'website', 'profile_url')
        }),
        ('Sponsorship Details', {
            'fields': ('package', 'start_date', 'end_date', 'status', 'is_featured')
        }),
        ('Analytics', {
            'fields': ('views',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['approve_sponsors', 'reject_sponsors', 'feature_sponsors', 'unfeature_sponsors']
    
    def approve_sponsors(self, request, queryset):
        updated = queryset.update(status='active')
        self.message_user(request, f'{updated} sponsors approved successfully.')
    approve_sponsors.short_description = "Approve selected sponsors"
    
    def reject_sponsors(self, request, queryset):
        updated = queryset.update(status='rejected')
        self.message_user(request, f'{updated} sponsors rejected.')
    reject_sponsors.short_description = "Reject selected sponsors"
    
    def feature_sponsors(self, request, queryset):
        updated = queryset.update(is_featured=True)
        self.message_user(request, f'{updated} sponsors featured.')
    feature_sponsors.short_description = "Feature selected sponsors"
    
    def unfeature_sponsors(self, request, queryset):
        updated = queryset.update(is_featured=False)
        self.message_user(request, f'{updated} sponsors unfeatured.')
    unfeature_sponsors.short_description = "Unfeature selected sponsors"

@admin.register(GoldSponsorBanner)
class GoldSponsorBannerAdmin(admin.ModelAdmin):
    list_display = ['sponsor', 'title', 'order', 'is_active', 'created_at']
    list_filter = ['is_active', 'sponsor']
    search_fields = ['title', 'sponsor__business_name']
    ordering = ['sponsor', 'order']

