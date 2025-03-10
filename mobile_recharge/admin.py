from django.contrib import admin

# Register your models here.

from .models import *

admin.site.register(Operator)
admin.site.register(Package)

class RechargeAdmin(admin.ModelAdmin):
    list_display = ('user','phone_number','operator', 'package', 'amount', 'created_at')
admin.site.register(Recharge, RechargeAdmin)
