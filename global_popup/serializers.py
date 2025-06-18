from rest_framework import serializers
from .models import PopupDesktop, PopupMobile, PopupView


class PopupDesktopSerializer(serializers.ModelSerializer):
    class Meta:
        model = PopupDesktop
        fields = '__all__'


class PopupMobileSerializer(serializers.ModelSerializer):
    class Meta:
        model = PopupMobile
        fields = '__all__'


class PopupViewSerializer(serializers.ModelSerializer):
    class Meta:
        model = PopupView
        fields = '__all__'
