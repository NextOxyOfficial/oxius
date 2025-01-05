from django.urls import path, include
from .views import *

urlpatterns = [
  path('upazila/',upazila),
  path('cities/',cities),
  path('regions/',regions),
  path('countries/',countries)
]