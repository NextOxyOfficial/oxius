from django.contrib import admin

from .models import *


admin.site.register(User)
admin.site.register(ClassifiedCategory)
admin.site.register(MicroGigCategory)
admin.site.register(MicroGigPostMedia)
admin.site.register(MicroGigPost)
admin.site.register(MicroGigPostTask)
admin.site.register(Balance)
admin.site.register(PendingTask)
admin.site.register(TargetCountry)
admin.site.register(TargetDevice)
admin.site.register(TargetNetwork)
admin.site.register(ClassifiedCategoryPost)
