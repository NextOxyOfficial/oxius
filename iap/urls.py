from django.urls import path

from .views import iap_products, iap_rtdn, iap_verify

urlpatterns = [
    path("iap/products/", iap_products, name="iap-products"),
    path("iap/verify/", iap_verify, name="iap-verify"),
    path("iap/rtdn/", iap_rtdn, name="iap-rtdn"),
]
