from django.contrib import admin, messages

from .models import AllianceDonation, OutreachDraft
from .tasks import dispatch_outreach


@admin.register(OutreachDraft)
class OutreachDraftAdmin(admin.ModelAdmin):
    list_display = ["company", "to_email", "category", "status", "scheduled_for", "sent_at", "created_at"]
    list_filter = ["status", "category", "created_at"]
    search_fields = ["company", "to_email", "subject", "notes"]
    readonly_fields = ["status", "scheduled_for", "sent_at", "error", "created_at", "updated_at"]
    ordering = ["-created_at"]
    actions = ["send_now", "mark_skipped"]

    fieldsets = (
        ("Recipient", {"fields": ("category", "company", "to_name", "to_email")}),
        ("Email", {"fields": ("subject", "body_html", "notes")}),
        ("Status", {"fields": ("status", "scheduled_for", "sent_at", "error",
                               "created_at", "updated_at")}),
    )

    def send_now(self, request, queryset):
        ids = [str(d.id) for d in queryset]
        queued = dispatch_outreach(ids)
        self.message_user(request, f"{queued} email(s) scheduled to send (staggered).")
    send_now.short_description = "Send selected (staggered)"

    def mark_skipped(self, request, queryset):
        n = queryset.update(status="skipped")
        self.message_user(request, f"{n} marked as skipped.", level=messages.WARNING)
    mark_skipped.short_description = "Skip selected"


@admin.register(AllianceDonation)
class AllianceDonationAdmin(admin.ModelAdmin):
    list_display = ["amount", "status", "donor_name", "donor_email", "created_at", "completed_at"]
    list_filter = ["status", "created_at"]
    search_fields = ["order_id", "donor_name", "donor_email", "donor_phone"]
    readonly_fields = [f.name for f in AllianceDonation._meta.fields]
    ordering = ["-created_at"]

    def has_add_permission(self, request):
        return False
