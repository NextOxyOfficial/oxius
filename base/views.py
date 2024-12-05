from django.shortcuts import render
from rest_framework import status
from rest_framework.response import Response
from rest_framework import generics
from .models import ClassifiedCategory
from .serializers import ClassifiedServicesSerializer

# Create your views here.


class GetProductDetailsView(generics.ListCreateAPIView):
    queryset = ClassifiedCategory.objects.filter().order_by('-created_at')
    serializer_class = ClassifiedServicesSerializer

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        # data = {
        #     "message": "Product details fetched successfully",
        #     "data": serializer.data,
        # }
        return Response(serializer.data, status=status.HTTP_200_OK)