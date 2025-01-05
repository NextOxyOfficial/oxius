from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Country, Region, City, Upazila
from rest_framework import status

@api_view(["GET"])
def countries(request):
    name_eng = request.GET.get('name_eng', None)
    name_ban = request.GET.get('name_ban', None)

    countries = Country.objects.all()

    if name_eng:
        countries = countries.filter(name_eng__icontains=name_eng)
    if name_ban:
        countries = countries.filter(name_ban__icontains=name_ban)

    data = [{"id": country.id, "name_eng": country.name_eng, "name_ban": country.name_ban} for country in countries]

    return Response(data, status=status.HTTP_200_OK)

@api_view(["GET"])
def regions(request):
    country_id = request.GET.get('country_id', None)
    name_eng = request.GET.get('name_eng', None)
    name_ban = request.GET.get('name_ban', None)

    regions = Region.objects.all()

    if country_id:
        regions = regions.filter(country_id=country_id)
    if name_eng:
        regions = regions.filter(country_name_eng__icontains=name_eng)
    if name_ban:
        regions = regions.filter(country_name_ban__icontains=name_ban)

    data = [{"id": region.id, "name_eng": region.name_eng, "name_ban": region.name_ban, "country": region.country.name_eng} for region in regions]

    return Response(data, status=status.HTTP_200_OK)

@api_view(["GET"])
def cities(request):
    region_id = request.GET.get('region_id', None)
    name_eng = request.GET.get('name_eng', None)
    name_ban = request.GET.get('name_ban', None)
    zip_code = request.GET.get('zip', None)

    cities = City.objects.all()

    if region_id:
        cities = cities.filter(region_id=region_id)
    if name_eng:
        cities = cities.filter(region_name_eng__icontains=name_eng)
    if name_ban:
        cities = cities.filter(region_name_ban__icontains=name_ban)
    if zip_code:
        cities = cities.filter(zip__icontains=zip_code)

    data = [{"id": city.id, "name_eng": city.name_eng, "name_ban": city.name_ban, "region": city.region.name_eng, "zip": city.zip} for city in cities]

    return Response(data, status=status.HTTP_200_OK)

@api_view(["GET"])
def upazila(request):
    city_id = request.GET.get('city_id', None)
    name_eng = request.GET.get('name_eng', None)
    name_ban = request.GET.get('name_ban', None)

    upazilas = Upazila.objects.all()

    if city_id:
        upazilas = upazilas.filter(city_id=city_id)
    if name_eng:
        upazilas = upazilas.filter(city_name_eng__icontains=name_eng)
    if name_ban:
        upazilas = upazilas.filter(city_name_ban__icontains=name_ban)

    data = [{"id": upazila.id, "name_eng": upazila.name_eng, "name_ban": upazila.name_ban, "city": upazila.city.name_eng} for upazila in upazilas]

    return Response(data, status=status.HTTP_200_OK)
