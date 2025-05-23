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

@admin.register(GoldSponsor)
class GoldSponsorAdmin(admin.ModelAdmin):
    list_display = ['business_name', 'contact_email', 'package', 'status', 'is_featured', 'start_date', 'end_date']
    list_filter = ['status', 'is_featured', 'package', 'created_at']
    search_fields = ['business_name', 'contact_email', 'phone_number']
    ordering = ['-created_at']
    readonly_fields = ['slug', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Business Information', {
            'fields': ('business_name', 'business_description', 'slug', 'logo')
        }),
        ('Contact Information', {
            'fields': ('contact_email', 'phone_number', 'website', 'profile_url')
        }),
        ('Sponsorship Details', {
            'fields': ('package', 'start_date', 'end_date', 'status', 'is_featured')
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

