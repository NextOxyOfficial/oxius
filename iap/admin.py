from django.contrib import admin

from .models import IapProduct, IapPurchase


@admin.register(IapProduct)
class IapProductAdmin(admin.ModelAdmin):
    list_display = (
        "kind",
        "google_product_id",
        "base_plan_id",
        "is_subscription",
        "diamonds",
        "duration_days",
        "price_label",
        "is_active",
        "sort_order",
    )
    list_editable = ("google_product_id", "base_plan_id", "is_active", "sort_order")
    list_filter = ("kind", "is_subscription", "is_active")
    search_fields = ("google_product_id", "title")


@admin.register(IapPurchase)
class IapPurchaseAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "kind",
        "google_product_id",
        "status",
        "is_subscription",
        "expiry_at",
        "created_at",
    )
    list_filter = ("kind", "status", "is_subscription")
    search_fields = (
        "user__email",
        "user__username",
        "google_product_id",
        "order_id",
        "purchase_token",
    )
    readonly_fields = (
        "user",
        "kind",
        "google_product_id",
        "purchase_token",
        "order_id",
        "ref_id",
        "is_subscription",
        "expiry_at",
        "raw",
        "created_at",
        "updated_at",
    )

    def has_add_permission(self, request):
        return False
