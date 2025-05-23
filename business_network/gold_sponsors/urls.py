from django.urls import path
from .views import SponsorshipPackageListView, GoldSponsorCreateView, GoldSponsorListView

urlpatterns = [
    path('packages/', SponsorshipPackageListView.as_view(), name='sponsorship-packages'),
    path('apply/', GoldSponsorCreateView.as_view(), name='gold-sponsor-apply'),
    path('list/', GoldSponsorListView.as_view(), name='gold-sponsor-list'),
]
