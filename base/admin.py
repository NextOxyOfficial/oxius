from django.contrib import admin

from .models import *


admin.site.register(User)
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
admin.site.register(NID)

