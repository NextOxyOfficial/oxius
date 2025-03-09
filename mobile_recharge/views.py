from rest_framework import generics, filters
from rest_framework.permissions import IsAuthenticated, AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from .models import *
from .serializers import *

class OperatorListView(generics.ListAPIView):
    queryset = Operator.objects.filter(active=True)
    serializer_class = OperatorSerializer
    permission_classes = [AllowAny]

class OperatorDetailView(generics.RetrieveAPIView):
    queryset = Operator.objects.filter(active=True)
    serializer_class = OperatorSerializer
    permission_classes = [AllowAny]

class PackageListView(generics.ListAPIView):
    queryset = Package.objects.filter(active=True)
    serializer_class = PackageSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['operator', 'type', 'popular']
    search_fields = ['type', 'price', 'data']

class PackageDetailView(generics.RetrieveAPIView):
    queryset = Package.objects.filter(active=True)
    serializer_class = PackageSerializer
    permission_classes = [AllowAny]

class RechargeListCreateView(generics.ListCreateAPIView):
    serializer_class = RechargeSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Recharge.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class RechargeDetailView(generics.RetrieveUpdateAPIView):
    serializer_class = RechargeSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Recharge.objects.filter(user=self.request.user)