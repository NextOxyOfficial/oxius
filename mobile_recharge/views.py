from rest_framework import generics, filters,status
from rest_framework.permissions import IsAuthenticated, AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.response import Response
from .models import *
from .serializers import *

from base.models import Balance

from django.db import transaction
from rest_framework.exceptions import ValidationError


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
        # Admin/staff can see all recharges
        if self.request.user.is_staff or self.request.user.is_superuser:
            return Recharge.objects.all().order_by('-created_at')
        # Regular users can only see their own recharges
        return Recharge.objects.filter(user=self.request.user).order_by('-created_at')
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                'status': 'error',
                'message': 'Invalid recharge details',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            recharge = self.perform_create(serializer)
            headers = self.get_success_headers(serializer.data)
            return Response({
                'status': 'success',
                'message': 'Recharge initiated successfully',
                'data': serializer.data
            }, status=status.HTTP_201_CREATED, headers=headers)
        except ValidationError as e:
            return Response({
                'status': 'error',
                'message': str(e),
            }, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({
                'status': 'error',
                'message': 'Failed to process recharge',
                'detail': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    @transaction.atomic
    def perform_create(self, serializer):
        user = self.request.user
        amount = serializer.validated_data.get('amount') or serializer.validated_data['package'].price
        
        # Check if user has sufficient balance
        if user.balance < amount:
            raise ValidationError(f"Insufficient balance. Required: ${amount}, Available: ${user.balance}")
        
        # Deduct amount from user balance
        user.balance -= amount
        user.save()
        
        # Create transaction history record
        Balance.objects.create(
            user=user,
            amount=amount,
            transaction_type='mobile_recharge',
            completed=True,
            approved=True,
            bank_status='completed',
            description=f"Mobile recharge for {serializer.validated_data['phone_number']}"
        )
        
        # Create the recharge record
        recharge = serializer.save(user=user)
        
        # Create notification for successful recharge
        try:
            from base.views import create_mobile_recharge_notification
            create_mobile_recharge_notification(
                user=user,
                amount=amount,
                phone_number=serializer.validated_data['phone_number']
            )
        except Exception as e:
            # Log error but don't fail the transaction
            print(f"Error creating recharge notification: {e}")
        
        return recharge

class RechargeDetailView(generics.RetrieveUpdateAPIView):
    serializer_class = RechargeSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Recharge.objects.filter(user=self.request.user)