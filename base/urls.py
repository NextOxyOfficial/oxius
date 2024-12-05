from django.urls import path
from .views import GetProductDetailsView

urlpatterns = [
  path('classified-services/',GetProductDetailsView.as_view())
]