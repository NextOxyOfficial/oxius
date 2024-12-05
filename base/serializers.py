from rest_framework import serializers
from .models import ClassifiedCategory

class ClassifiedServicesSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClassifiedCategory
        fields = '__all__'