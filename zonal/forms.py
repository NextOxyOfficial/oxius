"""Admin form for ZonalOffice — Division -> City cascading dropdowns.

The zone city must exactly match users' City values (which come from the
cities geo tables), so free typing invites typos. Instead we render a
Division (Region) select and a City select populated from the same tables;
a tiny JS file filters the city list to the chosen division.
"""
from django import forms

from .models import ZonalOffice


class CitySelectWidget(forms.Select):
    """Select whose options carry data-division so JS can cascade-filter."""

    def __init__(self, *args, division_by_city=None, **kwargs):
        super().__init__(*args, **kwargs)
        self.division_by_city = division_by_city or {}

    def create_option(self, name, value, *args, **kwargs):
        option = super().create_option(name, value, *args, **kwargs)
        division = self.division_by_city.get(str(value))
        if division:
            option["attrs"]["data-division"] = division
        return option


class ZonalOfficeAdminForm(forms.ModelForm):
    division = forms.ChoiceField(
        required=False,
        label="Division",
        help_text="বিভাগ সিলেক্ট  করলে নিচের City তালিকা শুধু সেই বিভাগের জেলা/শহর দেখাবে।",
    )

    class Meta:
        model = ZonalOffice
        fields = "__all__"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        division_choices = [("", "— বিভাগ সিলেক্ট  করুন —")]
        city_choices = [("", "— শহর/জেলা সিলেক্ট  করুন —")]
        division_by_city = {}
        try:
            from cities.models import City, Region

            regions = list(
                Region.objects.order_by("name_eng")
                .values_list("name_eng", flat=True)
                .distinct()
            )
            division_choices += [(r, r) for r in regions if (r or "").strip()]

            seen = set()
            for c in City.objects.select_related("region").order_by("name_eng"):
                name = (c.name_eng or "").strip()
                if not name or name.lower() in seen:
                    continue
                seen.add(name.lower())
                city_choices.append((name, name))
                division_by_city[name] = (
                    c.region.name_eng if c.region_id else ""
                )
        except Exception:
            # Geo tables unavailable (fresh db) — fall back to free text.
            pass

        self.fields["division"].choices = division_choices

        if len(city_choices) > 1:
            self.fields["city"] = forms.ChoiceField(
                choices=city_choices,
                label="City",
                widget=CitySelectWidget(division_by_city=division_by_city),
                help_text="এই জোনের শহর/জেলা — ইউজারদের প্রোফাইলের City-র সাথে মিলে যায়।",
            )
            # On edit, preselect the division the saved city belongs to.
            current = ""
            if self.instance and self.instance.pk:
                current = (self.instance.city or "").strip()
            if current and division_by_city.get(current):
                self.fields["division"].initial = division_by_city[current]

    class Media:
        js = ("zonal/zonal_office_cascade.js",)
