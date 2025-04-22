from django.contrib import admin
from .models import *
# Register your models here.

admin.site.register(NewsPost)
admin.site.register(NewsCategory)
admin.site.register(NewsPostComment)

@admin.register(TipsAndSuggestion)
class TipsAndSuggestionAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'author', 'created_at')
    search_fields = ('title', 'description', 'author__username')
    list_filter = ('created_at', 'updated_at')
    readonly_fields = ('id', 'created_at', 'updated_at')