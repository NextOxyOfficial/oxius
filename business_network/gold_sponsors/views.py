from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.decorators import api_view
from business_network.models import SponsorshipPackage, GoldSponsor
from .serializers import SponsorshipPackageSerializer, GoldSponsorCreateSerializer, GoldSponsorSerializer

class SponsorshipPackageListView(generics.ListAPIView):
    """Get all active sponsorship packages"""
    queryset = SponsorshipPackage.objects.filter(is_active=True).order_by('duration_months')
    serializer_class = SponsorshipPackageSerializer

class GoldSponsorCreateView(generics.CreateAPIView):
    """Create a new Gold Sponsor application"""
    queryset = GoldSponsor.objects.all()
    serializer_class = GoldSponsorCreateSerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        sponsor = serializer.save()
        
        # Return the created sponsor with full details
        response_serializer = GoldSponsorSerializer(sponsor)
        return Response(
            {
                'message': 'Gold Sponsor application submitted successfully!',
                'sponsor': response_serializer.data
            },
            status=status.HTTP_201_CREATED
        )

class GoldSponsorListView(generics.ListAPIView):
    """Get all active Gold Sponsors (for display purposes)"""
    queryset = GoldSponsor.objects.filter(status='active', is_featured=True).order_by('-created_at')
    serializer_class = GoldSponsorSerializer
