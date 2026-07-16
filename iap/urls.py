from django.urls import path

from .views import (
    iap_products,
    iap_resolve_token,
    iap_rtdn,
    iap_transfer,
    iap_verify,
)

urlpatterns = [
    path("iap/products/", iap_products, name="iap-products"),
    path("iap/verify/", iap_verify, name="iap-verify"),
    path("iap/resolve-token/", iap_resolve_token, name="iap-resolve-token"),
    path("iap/transfer/", iap_transfer, name="iap-transfer"),
    path("iap/rtdn/", iap_rtdn, name="iap-rtdn"),
]
