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
        # Always filter by the current user — admin access is via Django admin panel
        return Recharge.objects.filter(user=self.request.user).order_by('-created_at')

    def perform_create(self, serializer):
        """Charge the Adsy Pay balance, store the recharge, then hand it to the
        provider (or leave it pending for manual processing). The amount is taken
        from the selected package server-side so it can't be tampered with."""
        from .services import charge_balance, process_recharge

        user = self.request.user
        package = serializer.validated_data.get('package')
        amount = package.price if package else serializer.validated_data.get('amount')
        if not amount or amount <= 0:
            raise ValidationError('সঠিক রিচার্জ পরিমাণ দিন।')

        with transaction.atomic():
            ok, err = charge_balance(user, amount)
            if not ok:
                raise ValidationError(err)
            recharge = serializer.save(balance_charged=True, amount=amount)

        # Outside the charge transaction so a provider/network hiccup never rolls
        # back the (already-saved) request; failures auto-refund inside.
        process_recharge(recharge)
        return recharge

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
    
class RechargeDetailView(generics.RetrieveUpdateAPIView):
    serializer_class = RechargeSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Recharge.objects.filter(user=self.request.user)