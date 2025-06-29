from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.translation import gettext_lazy as _
from django.contrib.auth.forms import UserChangeForm, UserCreationForm
from django.utils.html import format_html
from django.urls import reverse
from .models import *


admin.site.register(DiamondPackages)
admin.site.register(ProductSlotPackage)
admin.site.register(EshopBanner)
admin.site.register(AILink)


class CustomUserChangeForm(UserChangeForm):
    class Meta(UserChangeForm.Meta):
        model = User


class CustomUserCreationForm(UserCreationForm):
    class Meta(UserCreationForm.Meta):
        model = User


class CustomUserAdmin(UserAdmin):
    form = CustomUserChangeForm
    add_form = CustomUserCreationForm

    list_display = ('email', 'first_name', 'balance', 'diamond_balance', 'age', 'gender', 'pending_balance', 'address',  'phone', 'kyc',  'is_active', 'date_joined',
                    'is_pro', 'pro_validity', 'is_topcontributor', 'store_name', 'store_username', 'store_logo', 'store_banner', 'store_address', 'store_description', 'product_limit')
    list_filter = ('is_vendor', 'is_active', 'user_type', 'kyc')
    list_per_page = 20

    def get_fieldsets(self, request, obj=None):
        if not obj:
            return self.add_fieldsets

        return [(None, {'fields': (
            'email',
            'password',
            'username',
            'otp',
            'first_name',
            'last_name',
            'name',
            'phone',
            'age', 'gender',
            'image',
            'about',
            'face_link',
            'instagram_link',
            'gmail_link',
            'whatsapp_link',
            'is_vendor',
            'is_active',
            'kyc_pending',
            'kyc',
            'is_topcontributor',
            'address',
            'country',
            'city',
            'state',
            'upazila',
            'zip',
            'balance',
            'pending_balance',
            'diamond_balance',
            'user_type',
            'refer',
            'refer_count',
            'commission_earned',
            'commission',
            'referral_code',
            'nid_number',
            'is_staff',
            'is_superuser',
            'groups',
            'user_permissions',
            'last_login',            'date_joined', 'is_pro', 'pro_validity', 'store_name', 'store_username', 'store_logo', 'store_banner',
            'store_address', 'store_description', 'product_limit'
        )})]

    def get_readonly_fields(self, request, obj=None):
        if obj:
            return ('change_password_button', 'referral_code')
        return ('referral_code',)

    def change_password_button(self, obj):
        if obj:
            url = reverse('admin:auth_user_password_change', args=[obj.pk])
            return format_html(
                '<a class="button" href="{}">Change Password</a>',
                url
            )
        return ''
    change_password_button.short_description = 'Change Password'

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'username', 'password1', 'password2'),
        }),
    )

    search_fields = ('email', 'username', 'phone')
    ordering = ('-date_joined',)


# Unregister any existing User admin
try:
    admin.site.unregister(User)
except admin.sites.NotRegistered:
    pass

# Register the custom admin
admin.site.register(User, CustomUserAdmin)


class ClassifiedCategoryAdmin(admin.ModelAdmin):
    list_display = ('title', 'created_at', 'updated_at')
    search_fields = ('title', 'search_keywords')
    fields = ('user', 'title', 'slug', 'business_type',
              'image', 'is_featured', 'search_keywords')


admin.site.register(ClassifiedCategory, ClassifiedCategoryAdmin)


class MicroGigCategoryAdmin(admin.ModelAdmin):
    list_display = ('title', 'created_at', 'updated_at')


admin.site.register(MicroGigCategory, MicroGigCategoryAdmin)


admin.site.register(MicroGigPostMedia)


class MicroGigPostAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'category',  'price', 'required_quantity', 'filled_quantity',
                    'total_cost', 'balance', 'active_gig', 'stop_gig', 'created_at', 'updated_at', 'gig_status')

    list_filter = ('user', 'category', 'active_gig',
                   'stop_gig', 'created_at', 'updated_at')

    @admin.display(ordering='-created_at')
    def created_at(self, obj):
        return obj.created_at


admin.site.register(MicroGigPost, MicroGigPostAdmin)


class MicroGigPostTaskAdmin(admin.ModelAdmin):
    list_display = ('user', 'gig', 'submit_details', 'created_at',
                    'approved', 'rejected', 'completed', 'reason')
    list_filter = ('user', 'approved', 'rejected', 'completed')

    autocomplete_fields = ['user']  # Enables search instead of a long dropdown

    @admin.display(ordering='-created_at')
    def created_at(self, obj):
        return obj.created_at


admin.site.register(MicroGigPostTask, MicroGigPostTaskAdmin)


class BalanceAdmin(admin.ModelAdmin):

    list_display = ('user', 'user__balance', 'bank_status', 'payment_method', 'card_number', 'payment_confirmed_at',
                    'payable_amount', 'received_amount', 'merchant_invoice_no', 'created_at', 'updated_at', 'completed', 'approved', 'rejected')

    list_filter = ('user', 'bank_status', 'payment_method', 'payment_confirmed_at',
                   'created_at', 'updated_at', 'completed', 'approved', 'rejected')

    list_editable = ('bank_status', 'payment_method',
                     'completed', 'approved', 'rejected')

    @admin.display(ordering="-created_at")
    def created_at(self, obj):
        return obj.created_at


admin.site.register(Balance, BalanceAdmin)


class PendingTaskAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'price', 'created_at', 'updated_at')


admin.site.register(PendingTask, PendingTaskAdmin)


class TargetCountryAdmin(admin.ModelAdmin):
    list_display = ('title', 'created_at', 'updated_at')


admin.site.register(TargetCountry, TargetCountryAdmin)


class TargetDeviceAdmin(admin.ModelAdmin):
    list_display = ('title', 'created_at', 'updated_at')


admin.site.register(TargetDevice, TargetDeviceAdmin)


class TargetNetworkAdmin(admin.ModelAdmin):
    list_display = ('title', 'created_at', 'updated_at')


admin.site.register(TargetNetwork, TargetNetworkAdmin)


class ClassifiedCategoryPostAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'category',  'price', 'location', 'negotiable', 'country',
                    'state', 'city', 'active_service', 'service_status', 'created_at', 'updated_at')
    list_filter = ('service_status', 'negotiable', 'active_service')
    search_fields = ('title',)
    list_per_page = 20
    ordering = ['-created_at']  # Most recent first

    def get_queryset(self, request):
        """Override queryset to ensure proper ordering"""
        queryset = super().get_queryset(request)
        return queryset.order_by('-created_at')

    @admin.display(ordering="-created_at")
    def created_at(self, obj):
        return obj.created_at


admin.site.register(ClassifiedCategoryPost, ClassifiedCategoryPostAdmin)

admin.site.register(Logo)
admin.site.register(AuthenticationBanner)


class AdminNoticeAdmin(admin.ModelAdmin):
    list_display = ('title', 'notification_type', 'user',
                    'amount', 'is_read', 'created_at', 'updated_at')
    list_filter = ('notification_type', 'is_read', 'created_at', 'user')
    search_fields = ('title', 'message', 'user__email',
                     'user__username', 'reference_id')
    list_editable = ('is_read',)
    fieldsets = (
        ('Notification Information', {
            'fields': ('title', 'message', 'notification_type')
        }),
        ('Targeting', {
            'fields': ('user',),
            'description': 'Leave user blank for global notifications visible to all users'
        }),
        ('Additional Details', {
            'fields': ('amount', 'reference_id', 'is_read'),
            'classes': ('collapse',)
        }),
    )

    def get_queryset(self, request):
        queryset = super().get_queryset(request)
        return queryset.select_related('user')


admin.site.register(AdminNotice, AdminNoticeAdmin)

admin.site.register(ClassifiedCategoryPostMedia)


class NidAdmin(admin.ModelAdmin):
    list_display = ('user', 'approved', 'rejected', 'completed',
                    'front_image', 'back_image', 'selfie_image', 'other_document_image')
    list_filter = ('approved', 'rejected', 'completed')
    list_editable = ('approved', 'rejected')

    def front_image(self, obj):
        if obj.front:  # Assuming `front` is the field name for the front image
            return format_html('<a href="{}" target="_blank"><img src="{}" style="height: 50px;" /></a>', obj.front.url, obj.front.url)
        return "No Image"

    def back_image(self, obj):
        if obj.back:  # Assuming `back` is the field name for the back image
            return format_html('<a href="{}" target="_blank"><img src="{}" style="height: 50px;" /></a>', obj.back.url, obj.back.url)
        return "No Image"

    def selfie_image(self, obj):
        if obj.selfie:  # Assuming `selfie` is the field name for the selfie image
            return format_html('<a href="{}" target="_blank"><img src="{}" style="height: 50px;" /></a>', obj.selfie.url, obj.selfie.url)
        return "No Image"

    def other_document_image(self, obj):
        if obj.other_document:  # Assuming `other_document` is the field name for the other document image
            return format_html('<a href="{}" target="_blank"><img src="{}" style="height: 50px;" /></a>', obj.other_document.url, obj.other_document.url)
        return "No Image"

    front_image.short_description = 'Front Image'
    back_image.short_description = 'Back Image'
    selfie_image.short_description = 'Selfie'
    other_document_image.short_description = 'Other Document'


admin.site.register(NID, NidAdmin)


class ReferBonusAdmin(admin.ModelAdmin):
    list_display = ('created_at', 'user', 'amount')


admin.site.register(ReferBonus, ReferBonusAdmin)


class FaqAdmin(admin.ModelAdmin):
    list_display = ('label', 'get_content', 'created_at', 'updated_at')
    search_fields = ('label', 'content')

    def get_content(self, obj):
        # Return first 50 chars of stripped HTML content
        from django.utils.html import strip_tags
        return strip_tags(obj.content)[:50] + '...'
    get_content.short_description = 'Content'


admin.site.register(Faq, FaqAdmin)
admin.site.register(ProductCategory)
admin.site.register(ProductMedia)


class ProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'owner__store_name', 'sale_price',
                    'regular_price', 'created_at', 'updated_at')
    filter_horizontal = ('batches', 'divisions', 'category',
                         'benefits', 'faqs', 'trust_badges')
    search_fields = ('name', 'owner__email', 'owner__username',
                     'owner__store_name', 'slug', 'description', 'short_description')
    list_per_page = 10

    fieldsets = (
        ('Basic Information', {
            'fields': ('owner', 'name', 'image', 'slug', 'description', 'short_description', )
        }),
        ('Pricing & Inventory', {
            'fields': ('regular_price', 'sale_price', 'quantity', 'weight')
        }),        ('Categories & Organization', {
            'fields': ('category', 'batches', 'divisions', 'is_featured', 'is_active')
        }),
        ('Educational Classification', {
            'fields': ('is_science', 'is_commerce', 'is_humanities', 'is_advanced'),
            'classes': ('collapse',)
        }),
        ('Delivery Information', {
            'fields': ('is_free_delivery', 'delivery_fee_free', 'delivery_fee_inside_dhaka',
                       'delivery_fee_outside_dhaka', 'delivery_information'),
            'classes': ('collapse',)
        }),
        ('Marketing Content', {
            'fields': ('benefits_title', 'benefits_cta', 'benefits',
                       'faqs_title', 'faqs_subtitle', 'faqs',
                       'trust_badges'),
            'classes': ('collapse',)
        }),
        ('Call to Action', {
            'fields': ('cta_title', 'cta_subtitle', 'cta_button_text', 'cta_button_subtext',
                       'cta_badge1', 'cta_badge2', 'cta_badge3'),
            'classes': ('collapse',)
        }),
    )


admin.site.register(Product, ProductAdmin)


class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ('user', 'months', 'total')


admin.site.register(Subscription, SubscriptionAdmin)
admin.site.register(OrderItem)


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ('product', 'product_owner', 'quantity', 'price',
                       'created_at', 'updated_at', )
    can_delete = False

    def product_owner(self, obj):
        if obj.product and obj.product.owner:
            return obj.product.owner.store_name  # or .shop_name if your User model has it
        return "-"
    product_owner.short_description = 'Product Owner'


class OrderAdmin(admin.ModelAdmin):
    list_display = ('order_number', 'created_at', 'updated_at', 'product_owners_shops',
                    'user', 'order_status', 'total', 'payment_method',)
    readonly_fields = ('order_number', 'created_at', 'updated_at')

    fieldsets = (
        ('Order Details', {
            'fields': ('order_number', 'user', 'order_status', 'total', 'payment_method')

        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    inlines = [OrderItemInline]

    @admin.display(description='Product Owners / Shops')
    def product_owners_shops(self, obj):
        owners_shops = []
        for item in obj.items.all():
            print(f"Processing item: {item}")
            if item.product and item.product.owner:
                owners_shops.append(
                    f"{item.product.owner.store_name}"
                )
        # Remove duplicates
        unique_shops = list(set(owners_shops))
        return ", ".join(unique_shops)

    @admin.display(ordering='-created_at')
    def created_at(self, obj):
        return obj.created_at


admin.site.register(Order, OrderAdmin)
admin.site.register(BannerImage)
admin.site.register(ShopBannerImage)
admin.site.register(ProductBenefit)
admin.site.register(ProductFAQ)
admin.site.register(ProductTrustBadge)
admin.site.register(BNLogo)
admin.site.register(NewsLogo)


class DiamondTransactionAdmin(admin.ModelAdmin):
    list_display = ('user', 'to_user', 'transaction_type', 'amount',
                    'cost', 'completed', 'approved', 'rejected', 'created_at')
    list_filter = ('transaction_type', 'completed', 'approved', 'rejected')
    search_fields = ('user__email', 'user__username',
                     'to_user__email', 'to_user__username', 'post_id')
    readonly_fields = ('created_at', 'updated_at')

    @admin.display(ordering='-created_at')
    def created_at(self, obj):
        return obj.created_at


admin.site.register(DiamondTransaction, DiamondTransactionAdmin)


@admin.register(AndroidAppVersion)
class AndroidAppVersionAdmin(admin.ModelAdmin):
    list_display = ('version_name', 'version_code', 'is_active',
                    'file_size_mb', 'download_link', 'created_at')
    list_filter = ('is_active', 'min_android_version')
    search_fields = ('version_name', 'version_code', 'release_notes')
    readonly_fields = ('created_at', 'updated_at')
    fieldsets = (
        ('Version Information', {
            'fields': ('version_name', 'version_code', 'is_active', 'min_android_version', 'file_size_mb')
        }),
        ('Download Details', {
            'fields': ('download_url', 'release_notes')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    def download_link(self, obj):
        if obj.download_url:
            return format_html('<a href="{}" target="_blank">Download Link</a>', obj.download_url)
        return "-"

    download_link.short_description = "Download"

    def save_model(self, request, obj, form, change):
        super().save_model(request, obj, form, change)
        # Clear cache or perform other actions as needed
