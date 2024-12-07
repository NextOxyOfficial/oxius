from django.contrib import admin

from .models import ClassifiedCategory,User


admin.site.register(User)
admin.site.register(ClassifiedCategory)
