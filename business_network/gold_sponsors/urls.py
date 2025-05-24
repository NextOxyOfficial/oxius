from django.urls import path
from .views import (
    SponsorshipPackageListView, 
    GoldSponsorCreateView, 
    GoldSponsorListView, 
    gold_sponsor_stats,
    user_gold_sponsors,
    update_gold_sponsor,
    delete_gold_sponsor,
    increment_sponsor_views,
    sponsor_banners
)

urlpatterns = [
    path('packages/', SponsorshipPackageListView.as_view(), name='sponsorship-packages'),
    path('apply/', GoldSponsorCreateView.as_view(), name='gold-sponsor-apply'),
    path('list/', GoldSponsorListView.as_view(), name='gold-sponsor-list'),
    path('stats/', gold_sponsor_stats, name='gold-sponsor-stats'),
    path('my-sponsors/', user_gold_sponsors, name='user-gold-sponsors'),
    path('update/<int:sponsor_id>/', update_gold_sponsor, name='update-gold-sponsor'),
    path('delete/<int:sponsor_id>/', delete_gold_sponsor, name='delete-gold-sponsor'),    path('increment-views/<int:sponsor_id>/', increment_sponsor_views, name='increment-sponsor-views'),
    path('<int:sponsor_id>/banners/', sponsor_banners, name='sponsor-banners'),
]
