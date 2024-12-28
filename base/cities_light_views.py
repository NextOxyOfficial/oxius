from rest_framework import viewsets
from rest_framework import filters
from django_filters.rest_framework import DjangoFilterBackend  # Correct import
from cities_light.models import City, Region, Country
from .serializers import CitySerializer, RegionSerializer, CountrySerializer
from django_filters import rest_framework as django_filters

class RegionFilter(django_filters.FilterSet):
    country = django_filters.CharFilter(field_name='country__name', lookup_expr='iexact')

    class Meta:
        model = Region
        fields = ['country']

class CityFilter(django_filters.FilterSet):
    region = django_filters.CharFilter(field_name='region__name', lookup_expr='iexact')
    country = django_filters.CharFilter(field_name='region__country__name', lookup_expr='iexact')

    class Meta:
        model = City
        fields = ['region', 'country']

class CityViewSet(viewsets.ModelViewSet):
    queryset = City.objects.all()
    serializer_class = CitySerializer
    filter_backends = (DjangoFilterBackend,)  # Use the correct DjangoFilterBackend
    filterset_class = CityFilter

class RegionViewSet(viewsets.ModelViewSet):
    queryset = Region.objects.all()
    serializer_class = RegionSerializer
    filter_backends = (DjangoFilterBackend,)  # Use the correct DjangoFilterBackend
    filterset_class = RegionFilter

class CountryViewSet(viewsets.ModelViewSet):
    queryset = Country.objects.all()
    serializer_class = CountrySerializer
