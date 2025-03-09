from rest_framework import generics, filters,status
from rest_framework.permissions import IsAuthenticated, AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.response import Response
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
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            print(serializer.errors)
            return Response({
                'status': 'error',
                'message': 'Invalid recharge details',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            self.perform_create(serializer)
            headers = self.get_success_headers(serializer.data)
            return Response({
                'status': 'success',
                'message': 'Recharge initiated successfully',
                'data': serializer.data
            }, status=status.HTTP_201_CREATED, headers=headers)
        except Exception as e:
            return Response({
                'status': 'error',
                'message': 'Failed to process recharge',
                'detail': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        print(serializer.errors)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class RechargeDetailView(generics.RetrieveUpdateAPIView):
    serializer_class = RechargeSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Recharge.objects.filter(user=self.request.user)