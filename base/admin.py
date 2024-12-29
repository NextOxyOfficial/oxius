from django.contrib import admin

from .models import *

class UserAdmin(admin.ModelAdmin):
    list_display = (
        'email', 'name', 'phone', 'user_type', 'is_vendor', 
        'is_active', 'kyc', 'kyc_pending', 'balance', 'pending_balance'
    )
    search_fields = ('email', 'phone', 'name')
    list_filter = ('user_type', 'is_active', 'is_vendor', 'kyc', 'kyc_pending')
    list_editable = ('is_active', 'is_vendor', 'user_type')
admin.site.register(User, UserAdmin)


class ClassifiedCategoryAdmin(admin.ModelAdmin):
    list_display = ('title', 'created_at', 'updated_at')
admin.site.register(ClassifiedCategory, ClassifiedCategoryAdmin)


class MicroGigCategoryAdmin(admin.ModelAdmin):
    list_display = ('title', 'created_at', 'updated_at')
admin.site.register(MicroGigCategory, MicroGigCategoryAdmin)

admin.site.register(MicroGigPostMedia)


class MicroGigPostAdmin(admin.ModelAdmin):
    list_display = ('title','user', 'category',  'price', 'required_quantity', 'filled_quantity', 'instructions',  'total_cost', 'balance', 'active_gig', 'stop_gig', 'created_at', 'updated_at', 'gig_status')
    
    list_filter = ('user', 'category', 'active_gig', 'stop_gig', 'created_at', 'updated_at')
    
admin.site.register(MicroGigPost, MicroGigPostAdmin)


class MicroGigPostTaskAdmin(admin.ModelAdmin):
    list_display = ('created_at', 'approved', 'rejected', 'completed')
    list_filter = ('approved', 'rejected', 'completed')
    
admin.site.register(MicroGigPostTask, MicroGigPostTaskAdmin)


class BalanceAdmin(admin.ModelAdmin):
    
    list_display = ('user', 'bank_status', 'payment_method','payment_confirmed_at','amount', 'payable_amount','received_amount','merchant_invoice_no','created_at', 'updated_at','completed','approved','rejected')
    
    list_filter = ('user', 'bank_status', 'payment_method','payment_confirmed_at','created_at', 'updated_at','completed','approved','rejected')
    
    list_editable = ('bank_status', 'payment_method','completed','approved','rejected')
    
admin.site.register(Balance, BalanceAdmin)


class PendingTaskAdmin(admin.ModelAdmin):
    list_display = ('title','user','title','price','created_at','updated_at')
    
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
    list_display = ('title', 'user', 'category',  'price','location','negotiable', 'country', 'state', 'city', 'instructions','active_service', 'service_status', 'updated_at')
    
admin.site.register(ClassifiedCategoryPost, ClassifiedCategoryPostAdmin)

admin.site.register(Logo)
admin.site.register(AuthenticationBanner)


class AdminNoticeAdmin(admin.ModelAdmin):
    list_display = ('title','message', 'created_at', 'updated_at')
admin.site.register(AdminNotice, AdminNoticeAdmin)

admin.site.register(ClassifiedCategoryPostMedia)


class NidAdmin(admin.ModelAdmin):
    list_display = ( 'user', 'approved', 'rejected', 'completed')
    list_filter = ('approved', 'rejected', 'completed')
admin.site.register(NID, NidAdmin)


class ReferBonusAdmin(admin.ModelAdmin):
    list_display = ('created_at', 'user', 'amount')
admin.site.register(ReferBonus, ReferBonusAdmin)

