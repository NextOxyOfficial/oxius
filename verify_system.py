#!/usr/bin/env python
"""
Simple verification script for Gold Sponsor System
"""
import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

print("🔍 Gold Sponsor System Verification")
print("=" * 50)

# Test 1: Check Models Import
try:
    from business_network.models import GoldSponsor, SponsorshipPackage, GoldSponsorBanner
    from django.contrib.auth import get_user_model
    User = get_user_model()
    print("✅ All models imported successfully")
except Exception as e:
    print(f"❌ Model import failed: {e}")
    exit(1)

# Test 2: Check Database Tables
try:
    sponsor_count = GoldSponsor.objects.count()
    package_count = SponsorshipPackage.objects.count()
    banner_count = GoldSponsorBanner.objects.count()
    user_count = User.objects.count()
    
    print(f"✅ Database tables accessible:")
    print(f"   • Users: {user_count}")
    print(f"   • Sponsorship Packages: {package_count}")
    print(f"   • Gold Sponsors: {sponsor_count}")
    print(f"   • Sponsor Banners: {banner_count}")
except Exception as e:
    print(f"❌ Database access failed: {e}")

# Test 3: Check API Views Import
try:
    from business_network.gold_sponsors.views import (
        SponsorshipPackageListView,
        GoldSponsorCreateView,
        user_gold_sponsors,
        increment_sponsor_views
    )
    print("✅ API views imported successfully")
except Exception as e:
    print(f"❌ API views import failed: {e}")

# Test 4: Check Serializers
try:
    from business_network.gold_sponsors.serializers import (
        GoldSponsorSerializer,
        GoldSponsorCreateSerializer,
        SponsorshipPackageSerializer
    )
    print("✅ Serializers imported successfully")
except Exception as e:
    print(f"❌ Serializers import failed: {e}")

# Test 5: Check Admin
try:
    from business_network.admin import GoldSponsorAdmin, SponsorshipPackageAdmin
    print("✅ Admin classes imported successfully")
except Exception as e:
    print(f"❌ Admin import failed: {e}")

# Test 6: Check Frontend Components
frontend_components = [
    'frontend/components/adsy-business-network/user-sponsors.vue',
    'frontend/components/business-network/GoldSponsorModal.vue',
    'frontend/components/business-network/GoldSponsorsSlider.vue'
]

print("✅ Frontend Components:")
for component in frontend_components:
    if os.path.exists(component):
        print(f"   ✅ {component}")
    else:
        print(f"   ❌ {component}")

# Test 7: Check URLs
try:
    from business_network.gold_sponsors.urls import urlpatterns
    print(f"✅ Gold Sponsor URLs configured ({len(urlpatterns)} endpoints)")
except Exception as e:
    print(f"❌ URL configuration failed: {e}")

print("\n" + "=" * 50)
print("🎉 System verification completed!")
