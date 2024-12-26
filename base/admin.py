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
admin.site.register(ClassifiedCategory)
admin.site.register(MicroGigCategory)
admin.site.register(MicroGigPostMedia)
admin.site.register(MicroGigPost)
class MicroGigPostTaskAdmin(admin.ModelAdmin):
    list_display = ('created_at', 'approved', 'rejected', 'completed')
    list_filter = ('approved', 'rejected', 'completed')
admin.site.register(MicroGigPostTask, MicroGigPostTaskAdmin)
admin.site.register(Balance)
admin.site.register(PendingTask)
admin.site.register(TargetCountry)
admin.site.register(TargetDevice)
admin.site.register(TargetNetwork)
admin.site.register(ClassifiedCategoryPost)
admin.site.register(Logo)
admin.site.register(AdminNotice)
admin.site.register(ClassifiedCategoryPostMedia)
class NidAdmin(admin.ModelAdmin):
    list_display = ( 'user', 'approved', 'rejected', 'completed')
    list_filter = ('approved', 'rejected', 'completed')
admin.site.register(NID, NidAdmin)

