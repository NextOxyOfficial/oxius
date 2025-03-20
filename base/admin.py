from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.translation import gettext_lazy as _
from django.contrib.auth.forms import UserChangeForm, UserCreationForm
from django.utils.html import format_html
from django.urls import reverse
from .models import *


# class CustomUserChangeForm(UserChangeForm):
#     class Meta(UserChangeForm.Meta):
#         model = User

# class CustomUserCreationForm(UserCreationForm):
#     class Meta(UserCreationForm.Meta):
#         model = User

# class CustomUserAdmin(UserAdmin):
#     # form = CustomUserChangeForm
#     # add_form = CustomUserCreationForm
    
#     list_display = ('email', 'username', 'phone', 'is_vendor', 'is_active')
#     list_filter = ('is_vendor', 'is_active', 'user_type', 'kyc')
    
#     # def get_fieldsets(self, request, obj=None):
#     #     if not obj:
#     #         return self.add_fieldsets
        
#     #     return (
#     #         (None, {'fields': ('email', 'password', 'change_password_button')}),
#     #         ('Personal info', {'fields': ('username', 'name', 'phone', 'image', 'about')}),
#     #         ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'user_type')}),
#     #         ('Important dates', {'fields': ('last_login', 'date_joined')}),
#     #     )
    
#     # def get_readonly_fields(self, request, obj=None):
#     #     if obj:
#     #         return ('change_password_button',)
#     #     return ()

#     # def change_password_button(self, obj):
#     #     if obj:
#     #         url = reverse('admin:auth_user_password_change', args=[obj.pk])
#     #         return format_html(
#     #             '<a class="button" href="{}">Change Password</a>',
#     #             url
#     #         )
#     #     return ''
#     # change_password_button.short_description = 'Change Password'
    
#     add_fieldsets = (
#         (None, {
#             'classes': ('wide',),
#             'fields': ('email', 'username', 'password1', 'password2'),
#         }),
#     )
    
#     search_fields = ('email', 'username', 'phone')
#     ordering = ('email',)

# # Unregister any existing User admin
# try:
#     admin.site.unregister(User)
# except admin.sites.NotRegistered:
#     pass

# # Register the custom admin
# admin.site.register(User, CustomUserAdmin)
# admin.site.register(User)

class CustomUserChangeForm(UserChangeForm):
    class Meta(UserChangeForm.Meta):
        model = User

class CustomUserCreationForm(UserCreationForm):
    class Meta(UserCreationForm.Meta):
        model = User

class CustomUserAdmin(UserAdmin):
    form = CustomUserChangeForm
    add_form = CustomUserCreationForm
    
    list_display = ('email','first_name','balance','pending_balance','address',  'phone', 'kyc',  'is_active', 'date_joined')
    list_filter = ('is_vendor', 'is_active', 'user_type', 'kyc')
    
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
            'address',
            'city',
            'state',
            'zip',
            'balance',
            'pending_balance',
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
            'last_login',
            'date_joined'
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
admin.site.register(ClassifiedCategory, ClassifiedCategoryAdmin)


class MicroGigCategoryAdmin(admin.ModelAdmin):
    list_display = ('title', 'created_at', 'updated_at')
admin.site.register(MicroGigCategory, MicroGigCategoryAdmin)


admin.site.register(MicroGigPostMedia)


class MicroGigPostAdmin(admin.ModelAdmin):
    list_display = ('title','user', 'category',  'price', 'required_quantity', 'filled_quantity',  'total_cost', 'balance', 'active_gig', 'stop_gig', 'created_at', 'updated_at', 'gig_status')
    
    list_filter = ('user', 'category', 'active_gig', 'stop_gig', 'created_at', 'updated_at')
    
    @admin.display(ordering='-created_at')
    def created_at(self,obj):
        return obj.created_at
        
admin.site.register(MicroGigPost, MicroGigPostAdmin)


class MicroGigPostTaskAdmin(admin.ModelAdmin):
    list_display = ('user', 'gig', 'submit_details', 'created_at', 'approved', 'rejected', 'completed', 'reason')
    list_filter = ('user', 'approved', 'rejected', 'completed')
    
    autocomplete_fields = ['user']  # Enables search instead of a long dropdown
    
    @admin.display(ordering='-created_at')
    def created_at(self, obj):
        return obj.created_at

admin.site.register(MicroGigPostTask, MicroGigPostTaskAdmin)


class BalanceAdmin(admin.ModelAdmin):
    
    list_display = ('user','user__balance', 'bank_status', 'payment_method','card_number','payment_confirmed_at', 'payable_amount','received_amount','merchant_invoice_no','created_at', 'updated_at','completed','approved','rejected')
    
    list_filter = ('user', 'bank_status', 'payment_method','payment_confirmed_at','created_at', 'updated_at','completed','approved','rejected')
    
    list_editable = ('bank_status', 'payment_method','completed','approved','rejected')
    
    @admin.display(ordering="-created_at")
    def created_at(self,obj):
        return obj.created_at
    
admin.site.register(Balance, BalanceAdmin)


class PendingTaskAdmin(admin.ModelAdmin):
    list_display = ('title','user','price','created_at','updated_at')
    
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
    list_display = ('title', 'user', 'category',  'price','location','negotiable', 'country', 'state', 'city', 'active_service', 'service_status','created_at', 'updated_at')
    list_filter = ('service_status','negotiable','active_service')
    search_fields = ('title',)
    
    @admin.display(ordering="-created_at")
    def created_at(self,obj):
        return obj.created_at
    
admin.site.register(ClassifiedCategoryPost, ClassifiedCategoryPostAdmin)

admin.site.register(Logo)
admin.site.register(AuthenticationBanner)


class AdminNoticeAdmin(admin.ModelAdmin):
    list_display = ('title','message', 'created_at', 'updated_at')
admin.site.register(AdminNotice, AdminNoticeAdmin)

admin.site.register(ClassifiedCategoryPostMedia)


from django.utils.html import format_html
from django.contrib import admin
from .models import NID

class NidAdmin(admin.ModelAdmin):
    list_display = ('user', 'approved', 'rejected', 'completed', 'front_image', 'back_image', 'selfie_image', 'other_document_image')
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
    list_display = ('label', 'content', 'created_at', 'updated_at')
    
admin.site.register(Faq, FaqAdmin)
admin.site.register(ProductCategory)
admin.site.register(ProductMedia)

class ProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'sale_price','discount_price','created_at', 'updated_at')

admin.site.register(Product, ProductAdmin)