from django.contrib import admin

from .models import ClassifiedCategory,User,MicroGigCategory,MicroGigPost,Balance,PendingTask


admin.site.register(User)
admin.site.register(ClassifiedCategory)
admin.site.register(MicroGigCategory)
admin.site.register(MicroGigPost)
admin.site.register(Balance)
admin.site.register(PendingTask)
