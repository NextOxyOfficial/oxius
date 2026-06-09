from django.db import migrations

# Areas that were missing from the "Dhaka" city upazila list served by
# /api/geo/upazila/?city_name_eng=Dhaka (the classified location picker).
DHAKA_AREAS = [
    ("Savar", "সাভার"),
    ("Nabinagar", "নবীনগর"),
    ("Sripur", "শ্রীপুর"),
]


def add_dhaka_areas(apps, schema_editor):
    City = apps.get_model("cities", "City")
    Upazila = apps.get_model("cities", "Upazila")
    for city in City.objects.filter(name_eng__iexact="Dhaka"):
        for name_eng, name_ban in DHAKA_AREAS:
            Upazila.objects.get_or_create(
                city=city,
                name_eng=name_eng,
                defaults={"name_ban": name_ban},
            )


def remove_dhaka_areas(apps, schema_editor):
    Upazila = apps.get_model("cities", "Upazila")
    Upazila.objects.filter(
        city__name_eng__iexact="Dhaka",
        name_eng__in=[eng for eng, _ in DHAKA_AREAS],
    ).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("cities", "0002_alter_city_zip"),
    ]

    operations = [
        migrations.RunPython(add_dhaka_areas, remove_dhaka_areas),
    ]
