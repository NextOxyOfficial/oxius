from django import forms
from django.contrib import admin, messages
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


class GoldSponsorLocationInline(admin.TabularInline):
    """Target locations. No rows = shown all over Bangladesh; add rows to limit
    the sponsor to those divisions/cities/areas."""
    model = GoldSponsorLocation
    extra = 1
    verbose_name = "Target location (no rows = all Bangladesh)"
    verbose_name_plural = "Target locations (leave empty to show all over Bangladesh)"

class GoldSponsorAdminForm(forms.ModelForm):
    """Surfaces the wallet-charge rule as a normal form error.

    Creating a NEW Gold Sponsor charges the owner's wallet inside
    GoldSponsor.save(). When the balance is too low that save() raises a
    ValidationError, which the Django admin does NOT catch during save_model
    -> it bubbles up as a raw HTTP 500 ("couldn't add the sponsor"). Validating
    here instead means the admin shows exactly what's wrong, inline, and never
    reaches the failing save().
    """

    class Meta:
        model = GoldSponsor
        fields = '__all__'

    def clean(self):
        cleaned_data = super().clean()

        # Only a brand-new sponsor charges the wallet; editing one does not.
        if self.instance and self.instance.pk:
            return cleaned_data

        user = cleaned_data.get('user')
        package = cleaned_data.get('package')

        if user and not package:
            raise forms.ValidationError(
                "Select a Sponsorship Package — it sets the price charged to the "
                "owner and the sponsorship duration."
            )

        if user and package:
            price = package.price or 0
            balance = user.balance or 0
            if balance < price:
                who = getattr(user, 'email', None) or getattr(user, 'username', None) or str(user)
                raise forms.ValidationError(
                    "Insufficient wallet balance to create this Gold Sponsor. "
                    f"Creating it charges ৳{price} from {who}, whose wallet "
                    f"currently holds only ৳{balance}. Top up the user's "
                    "balance, or choose a cheaper package."
                )

        return cleaned_data


@admin.register(GoldSponsor)
class GoldSponsorAdmin(admin.ModelAdmin):
    form = GoldSponsorAdminForm
    list_display = ['business_name', 'user', 'contact_email', 'package', 'status', 'auto_renew', 'targeted_locations', 'views', 'is_featured', 'start_date', 'end_date']
    list_filter = ['status', 'auto_renew', 'is_featured', 'package', 'created_at', 'user']
    search_fields = ['business_name', 'contact_email', 'phone_number', 'user__username', 'user__email', 'locations__division', 'locations__city', 'locations__area']
    ordering = ['-created_at']
    readonly_fields = ['slug', 'views', 'created_at', 'updated_at']
    inlines = [GoldSponsorBannerInline, GoldSponsorLocationInline]

    def targeted_locations(self, obj):
        rows = obj.locations.all()
        if not rows:
            return "🇧🇩 All Bangladesh"
        return ", ".join(str(r) for r in rows[:3]) + ("…" if rows.count() > 3 else "")
    targeted_locations.short_description = 'Locations'
    
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
            'fields': ('package', 'start_date', 'end_date', 'status', 'is_featured', 'auto_renew')
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
    
    actions = [
        'approve_sponsors', 'reject_sponsors', 'feature_sponsors', 'unfeature_sponsors',
        'extend_one_period_charge', 'extend_one_period_free',
        'enable_auto_renew', 'disable_auto_renew',
    ]

    def extend_one_period_charge(self, request, queryset):
        """Renew/extend by one package period, charging each owner's wallet."""
        ok = 0
        for sponsor in queryset:
            result = sponsor.extend(charge=True, reason='admin')
            if result.get('ok'):
                ok += 1
            else:
                self.message_user(
                    request,
                    f'“{sponsor.business_name}”: could not extend — '
                    + (f"insufficient balance (needs ৳{result.get('price')}, "
                       f"has ৳{result.get('balance')})."
                       if result.get('reason') == 'insufficient_balance'
                       else result.get('reason', 'error')),
                    level=messages.WARNING,
                )
        if ok:
            self.message_user(request, f'{ok} sponsor(s) extended (wallet charged).')
    extend_one_period_charge.short_description = "Renew/extend 1 period (charge wallet)"

    def extend_one_period_free(self, request, queryset):
        """Comp extension — extend by one package period without charging."""
        ok = 0
        for sponsor in queryset:
            if sponsor.extend(charge=False, reason='admin_comp').get('ok'):
                ok += 1
        self.message_user(request, f'{ok} sponsor(s) extended free of charge.')
    extend_one_period_free.short_description = "Extend 1 period (free / comp)"

    def enable_auto_renew(self, request, queryset):
        updated = queryset.update(auto_renew=True)
        self.message_user(request, f'Auto-renew enabled for {updated} sponsor(s).')
    enable_auto_renew.short_description = "Enable auto-renew"

    def disable_auto_renew(self, request, queryset):
        updated = queryset.update(auto_renew=False)
        self.message_user(request, f'Auto-renew disabled for {updated} sponsor(s).')
    disable_auto_renew.short_description = "Disable auto-renew"

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



@admin.register(GoldSponsorReminderLog)
class GoldSponsorReminderLogAdmin(admin.ModelAdmin):
    """Audit trail of the multi-step renewal follow-ups (read-only)."""
    list_display = ['sponsor', 'stage', 'channel', 'sent_at']
    list_filter = ['stage', 'channel', 'sent_at']
    search_fields = ['sponsor__business_name', 'sponsor__user__email']
    ordering = ['-sent_at']

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False


@admin.register(GoldSponsorSettings)
class GoldSponsorSettingsAdmin(admin.ModelAdmin):
    """Pricing/limits for Gold Sponsor location targeting (singleton)."""
    list_display = ['specific_location_discount_percent', 'max_custom_locations', 'updated_at']
    list_editable = ['max_custom_locations']

    def has_add_permission(self, request):
        return not GoldSponsorSettings.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(ContentMonetizationApplication)
class ContentMonetizationApplicationAdmin(admin.ModelAdmin):
    """Review queue for content monetization applications."""

    list_display = [
        "user",
        "status",
        "followers_at_apply",
        "views_at_apply",
        "terms_accepted",
        "created_at",
        "reviewed_at",
    ]
    list_filter = ["status", "created_at"]
    search_fields = ["user__email", "user__username", "user__name", "user__phone"]
    readonly_fields = [
        "user",
        "followers_at_apply",
        "views_at_apply",
        "terms_accepted",
        "created_at",
    ]
    actions = ["approve_applications", "reject_applications"]

    @admin.action(description="Approve selected applications")
    def approve_applications(self, request, queryset):
        from django.utils import timezone as _tz
        updated = queryset.exclude(status="approved").update(
            status="approved", reviewed_at=_tz.now()
        )
        self.message_user(request, f"{updated} application(s) approved.", messages.SUCCESS)

    @admin.action(description="Reject selected applications")
    def reject_applications(self, request, queryset):
        from django.utils import timezone as _tz
        updated = queryset.exclude(status="rejected").update(
            status="rejected", reviewed_at=_tz.now()
        )
        self.message_user(request, f"{updated} application(s) rejected.", messages.SUCCESS)
