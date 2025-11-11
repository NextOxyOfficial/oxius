#!/usr/bin/env python
"""
Manual script to populate geo location data
Run this on your production server if the management command fails
"""

import os
import sys
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from cities.models import Country, Region, City, Upazila

def populate_data():
    # Create Bangladesh country
    country, created = Country.objects.get_or_create(
        name_eng="Bangladesh",
        defaults={'name_ban': "বাংলাদেশ"}
    )
    print(f"Country: {country.name_eng} {'created' if created else 'exists'}")

    # Sample regions (divisions)
    regions_data = [
        {"name_eng": "Dhaka", "name_ban": "ঢাকা"},
        {"name_eng": "Chattogram", "name_ban": "চট্টগ্রাম"},
        {"name_eng": "Rajshahi", "name_ban": "রাজশাহী"},
        {"name_eng": "Khulna", "name_ban": "খুলনা"},
        {"name_eng": "Barishal", "name_ban": "বরিশাল"},
        {"name_eng": "Sylhet", "name_ban": "সিলেট"},
        {"name_eng": "Rangpur", "name_ban": "রংপুর"},
        {"name_eng": "Mymensingh", "name_ban": "ময়মনসিংহ"},
    ]

    for region_data in regions_data:
        region, created = Region.objects.get_or_create(
            name_eng=region_data["name_eng"],
            country=country,
            defaults={'name_ban': region_data["name_ban"]}
        )
        print(f"Region: {region.name_eng} {'created' if created else 'exists'}")

        # Add sample cities for each region
        if region.name_eng == "Dhaka":
            cities_data = [
                {"name_eng": "Dhaka", "name_ban": "ঢাকা", "zip": "1000"},
                {"name_eng": "Gazipur", "name_ban": "গাজীপুর", "zip": "1700"},
                {"name_eng": "Narayanganj", "name_ban": "নারায়ণগঞ্জ", "zip": "1400"},
                {"name_eng": "Manikganj", "name_ban": "মানিকগঞ্জ", "zip": "1800"},
            ]
        elif region.name_eng == "Chattogram":
            cities_data = [
                {"name_eng": "Chattogram", "name_ban": "চট্টগ্রাম", "zip": "4000"},
                {"name_eng": "Cox's Bazar", "name_ban": "কক্সবাজার", "zip": "4700"},
                {"name_eng": "Cumilla", "name_ban": "কুমিল্লা", "zip": "3500"},
            ]
        else:
            # Add at least one city for other regions
            cities_data = [
                {"name_eng": region.name_eng, "name_ban": region.name_ban, "zip": "0000"}
            ]

        for city_data in cities_data:
            city, created = City.objects.get_or_create(
                name_eng=city_data["name_eng"],
                region=region,
                defaults={
                    'name_ban': city_data["name_ban"],
                    'zip': city_data["zip"]
                }
            )
            print(f"  City: {city.name_eng} {'created' if created else 'exists'}")

            # Add sample upazilas for major cities
            if city.name_eng == "Dhaka":
                upazilas_data = [
                    {"name_eng": "Dhanmondi", "name_ban": "ধানমন্ডি"},
                    {"name_eng": "Gulshan", "name_ban": "গুলশান"},
                    {"name_eng": "Uttara", "name_ban": "উত্তরা"},
                    {"name_eng": "Mirpur", "name_ban": "মিরপুর"},
                    {"name_eng": "Wari", "name_ban": "ওয়ারী"},
                ]
            elif city.name_eng == "Chattogram":
                upazilas_data = [
                    {"name_eng": "Panchlaish", "name_ban": "পাঁচলাইশ"},
                    {"name_eng": "Kotwali", "name_ban": "কোতোয়ালী"},
                    {"name_eng": "Chandgaon", "name_ban": "চাঁদগাঁও"},
                ]
            else:
                # Add at least one upazila for other cities
                upazilas_data = [
                    {"name_eng": f"{city.name_eng} Sadar", "name_ban": f"{city.name_ban} সদর"}
                ]

            for upazila_data in upazilas_data:
                upazila, created = Upazila.objects.get_or_create(
                    name_eng=upazila_data["name_eng"],
                    city=city,
                    defaults={'name_ban': upazila_data["name_ban"]}
                )
                print(f"    Upazila: {upazila.name_eng} {'created' if created else 'exists'}")

    # Print final counts
    print(f"\nFinal counts:")
    print(f"Countries: {Country.objects.count()}")
    print(f"Regions: {Region.objects.count()}")
    print(f"Cities: {City.objects.count()}")
    print(f"Upazilas: {Upazila.objects.count()}")

if __name__ == "__main__":
    populate_data()
    print("✅ Geo location data populated successfully!")
