from django.contrib import admin

from .models import ClassifiedCategory,User,MicroGigCategory,MicroGigPostMedia,MicroGigPost,MicroGigPostTask, Balance,PendingTask


admin.site.register(User)
admin.site.register(ClassifiedCategory)
admin.site.register(MicroGigCategory)
admin.site.register(MicroGigPostMedia)
admin.site.register(MicroGigPost)
admin.site.register(MicroGigPostTask)
admin.site.register(Balance)
admin.site.register(PendingTask)
