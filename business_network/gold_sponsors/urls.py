from django.urls import path
from .views import SponsorshipPackageListView, GoldSponsorCreateView, GoldSponsorListView, gold_sponsor_stats

urlpatterns = [
    path('packages/', SponsorshipPackageListView.as_view(), name='sponsorship-packages'),
    path('apply/', GoldSponsorCreateView.as_view(), name='gold-sponsor-apply'),
    path('list/', GoldSponsorListView.as_view(), name='gold-sponsor-list'),
    path('stats/', gold_sponsor_stats, name='gold-sponsor-stats'),
]
