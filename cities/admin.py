from django.contrib import admin
from .models import Country, Region, City, Upazila

class CountryAdmin(admin.ModelAdmin):
    list_display = ('name_eng', 'name_ban')
    search_fields = ('name_eng', 'name_ban')

class RegionAdmin(admin.ModelAdmin):
    list_display = ('name_eng', 'name_ban', 'country')
    search_fields = ('name_eng', 'name_ban')
    list_filter = ('country',)

class CityAdmin(admin.ModelAdmin):
    list_display = ('name_eng', 'name_ban', 'region', 'zip')
    search_fields = ('name_eng', 'name_ban', 'zip')
    list_filter = ('region',)

class UpazilaAdmin(admin.ModelAdmin):
    list_display = ('name_eng', 'name_ban', 'city')
    search_fields = ('name_eng', 'name_ban')
    list_filter = ('city',)

# Register the models with their respective admin classes
admin.site.register(Country, CountryAdmin)
admin.site.register(Region, RegionAdmin)
admin.site.register(City, CityAdmin)
admin.site.register(Upazila, UpazilaAdmin)
