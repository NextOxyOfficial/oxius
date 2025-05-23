from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.decorators import api_view
from django.db.models import Count
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

@api_view(['GET'])
def gold_sponsor_stats(request):
    """Get Gold Sponsor statistics for sidebar display"""
    try:
        # Count active sponsors
        active_count = GoldSponsor.objects.filter(status='active').count()
        
        # Get featured sponsors (limit to 3 for sidebar)
        featured_sponsors = GoldSponsor.objects.filter(
            status='active', 
            is_featured=True
        ).order_by('-created_at')[:3]
        
        # Serialize featured sponsors for response
        featured_sponsors_data = []
        for sponsor in featured_sponsors:
            featured_sponsors_data.append({
                'id': sponsor.id,
                'name': sponsor.business_name,
                'image': sponsor.logo.url if sponsor.logo else None,
                'website': sponsor.website,
                'business_description': sponsor.business_description
            })
        
        # For now, we'll use a mock total views count
        # In a real implementation, you might track views in a separate model
        total_views = active_count * 1250  # Mock calculation
        
        return Response({
            'active_count': active_count,
            'total_views': total_views,
            'featured_sponsors': featured_sponsors_data
        })
    except Exception as e:
        return Response(
            {'error': 'Failed to fetch sponsor stats'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
