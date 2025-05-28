from rest_framework import generics, status
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.decorators import api_view
from rest_framework.permissions import IsAuthenticated
from django.db import models
from business_network.models import SponsorshipPackage, GoldSponsor,GoldSponsorBanner
from .serializers import SponsorshipPackageSerializer, GoldSponsorCreateSerializer, GoldSponsorSerializer

class SponsorshipPackageListView(generics.ListAPIView):
    """Get all active sponsorship packages"""
    queryset = SponsorshipPackage.objects.filter(is_active=True).order_by('duration_months')
    serializer_class = SponsorshipPackageSerializer

class GoldSponsorCreateView(generics.CreateAPIView):
    """Create a new Gold Sponsor application"""
    queryset = GoldSponsor.objects.all()
    serializer_class = GoldSponsorCreateSerializer
    permission_classes = [IsAuthenticated]
    
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
    queryset = GoldSponsor.objects.filter(status='active', is_featured=True).order_by('?')
    serializer_class = GoldSponsorSerializer

@api_view(['GET'])
def gold_sponsor_stats(request):
    """Get Gold Sponsor statistics for sidebar display"""
    try:
        # Check if user is logged in
        user_sponsors_data = []
        total_views = 0
        
        if request.user.is_authenticated:
            print(f"DEBUG: User is authenticated: {request.user.username}")
            
            # Get the user's sponsors (regardless of status for display in 'My Sponsorships')
            user_sponsors = GoldSponsor.objects.filter(
                user=request.user
            ).order_by('-created_at')
            
            print(f"DEBUG: Found {user_sponsors.count()} sponsors for user")
            for s in user_sponsors:
                print(f"DEBUG: Sponsor: {s.business_name}, Status: {s.status}")
            
            # Count active user sponsors
            active_count = user_sponsors.filter(status='active').count()
            print(f"DEBUG: Active sponsors count: {active_count}")
            
            # Calculate total views from all active sponsors
            if active_count > 0:
                total_views = GoldSponsor.objects.filter(
                    user=request.user,
                    status='active'
                ).aggregate(models.Sum('views'))['views__sum'] or 0
                print(f"DEBUG: Total views: {total_views}")
            
            # Limit to top 5 sponsors for display
            user_sponsors = user_sponsors[:5]
            
            # Serialize user's sponsors
            for sponsor in user_sponsors:
                print(f"DEBUG: Processing sponsor: {sponsor.business_name}")
                
                # Check if logo exists and is valid
                logo_url = None
                if sponsor.logo:
                    try:
                        logo_url = sponsor.logo.url
                        print(f"DEBUG: Logo URL: {logo_url}")
                    except:
                        print(f"DEBUG: Error getting logo URL")
                
                sponsor_data = {
                    'id': sponsor.id,
                    'name': sponsor.business_name,
                    'image': logo_url,
                    'website': sponsor.website,
                    'business_description': sponsor.business_description,
                    'status': sponsor.status
                }
                user_sponsors_data.append(sponsor_data)
                print(f"DEBUG: Added sponsor data: {sponsor_data}")
        else:
            print("DEBUG: User is not authenticated")
            active_count = 0
        
        response_data = {
            'active_count': active_count,
            'total_views': total_views,
            'featured_sponsors': user_sponsors_data
        }
        print(f"DEBUG: Sending response: {response_data}")
        return Response(response_data)
    except Exception as e:
        return Response(
            {'error': 'Failed to fetch sponsor stats'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
def user_gold_sponsors(request):
    """Get Gold Sponsors created by the current user"""
    if not request.user.is_authenticated:
        return Response({'error': 'Authentication required'}, status=status.HTTP_401_UNAUTHORIZED)
    
    try:
        # Get user's sponsors
        sponsors = GoldSponsor.objects.filter(
            user=request.user
        ).order_by('-created_at')
        
        # Serialize sponsors
        serializer = GoldSponsorSerializer(sponsors, many=True)
        
        return Response({
            'user_sponsors': serializer.data,
            'count': sponsors.count()
        })
    except Exception as e:
        return Response(
            {'error': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['PUT'])
def update_gold_sponsor(request, sponsor_id):
    """Update a Gold Sponsor (only owner can update)"""
    if not request.user.is_authenticated:
        return Response({'error': 'Authentication required'}, status=status.HTTP_401_UNAUTHORIZED)
    
    try:
        sponsor = GoldSponsor.objects.get(id=sponsor_id, user=request.user)
    except GoldSponsor.DoesNotExist:
        return Response({'error': 'Sponsor not found or you do not have permission to edit'}, 
                       status=status.HTTP_404_NOT_FOUND)
    
    try:
        serializer = GoldSponsorCreateSerializer(sponsor, data=request.data, partial=True)
        if serializer.is_valid():
            updated_sponsor = serializer.save()
            response_serializer = GoldSponsorSerializer(updated_sponsor)
            return Response({
                'message': 'Sponsor updated successfully!',
                'sponsor': response_serializer.data
            })
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
def delete_gold_sponsor(request, sponsor_id):
    """Delete a Gold Sponsor (only owner can delete)"""
    if not request.user.is_authenticated:
        return Response({'error': 'Authentication required'}, status=status.HTTP_401_UNAUTHORIZED)
    
    try:
        sponsor = GoldSponsor.objects.get(id=sponsor_id, user=request.user)
    except GoldSponsor.DoesNotExist:
        return Response({'error': 'Sponsor not found or you do not have permission to delete'}, 
                       status=status.HTTP_404_NOT_FOUND)
    
    try:
        sponsor_name = sponsor.business_name
        sponsor.delete()
        return Response({
            'message': f'Sponsor "{sponsor_name}" deleted successfully!'
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def increment_sponsor_views(request, sponsor_id):
    """Increment views count for a sponsor"""
    try:
        sponsor = GoldSponsor.objects.get(id=sponsor_id, status='active')
        sponsor.increment_views()
        return Response({
            'message': 'Views incremented',
            'views': sponsor.views
        })
    except GoldSponsor.DoesNotExist:
        return Response({'error': 'Sponsor not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def sponsor_banners(request, sponsor_id):
    """Get banners for a specific sponsor"""
    try:
        # sponsor = GoldSponsor.objects.get(id=sponsor_id, status='active')
        banners = GoldSponsorBanner.objects.filter(sponsor=sponsor_id,is_active=True).order_by('order')
        
        banner_data = [{
            'id': banner.id,
            'title': banner.title,
            'image': request.build_absolute_uri(banner.image.url) if banner.image else None,
            'link_url': banner.link_url,
            'order': banner.order,
            'is_active': banner.is_active
        } for banner in banners]
        
        return Response( banner_data,status=status.HTTP_200_OK)
    except GoldSponsor.DoesNotExist:
        return Response({'error': 'Sponsor not found'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=500)
