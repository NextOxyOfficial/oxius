from decimal import Decimal
from rest_framework import generics, status, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly, AllowAny
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q, Sum
from django.db import models
from .models import RaiseUpPost, RaiseUpPostDetail, UserProfile, Donation
from .serializers import RaiseUpPostSerializer, RaiseUpPostCreateSerializer, RaiseUpPostDetailSerializer

class RaiseUpPostPagination(PageNumberPagination):
    page_size = 12
    page_size_query_param = 'page_size'
    max_page_size = 50

class RaiseUpPostListView(generics.ListCreateAPIView):
    queryset = RaiseUpPost.objects.filter(is_active=True)
    serializer_class = RaiseUpPostSerializer
    pagination_class = RaiseUpPostPagination
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['stage', 'sector', 'risk_level', 'funding_type']
    search_fields = ['title', 'summary', 'sector', 'city', 'poster__username', 'poster__first_name', 'poster__last_name']
    ordering_fields = ['created_at', 'raised', 'goal', 'progress_percent']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return RaiseUpPostCreateSerializer
        return RaiseUpPostSerializer
    
    def create(self, request, *args, **kwargs):
        """Override create to add detailed error logging and KYC verification"""
        # Check KYC verification
        try:
            user_profile = UserProfile.objects.get(user=request.user)
            if not user_profile.kyc_verified:
                return Response({
                    'success': False,
                    'message': 'KYC verification required. You must complete KYC verification to post on Raise Up.'
                }, status=status.HTTP_403_FORBIDDEN)
        except UserProfile.DoesNotExist:
            return Response({
                'success': False,
                'message': 'User profile not found. Please complete your profile setup.'
            }, status=status.HTTP_403_FORBIDDEN)
        
        print("=" * 50)
        print("POST Request Data:", request.data)
        print("=" * 50)
        
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            print("Validation Errors:", serializer.errors)
            print("=" * 50)
            return Response({
                'success': False,
                'errors': serializer.errors,
                'message': 'Validation failed'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            self.perform_create(serializer)
            headers = self.get_success_headers(serializer.data)
            return Response({
                'success': True,
                'data': serializer.data,
                'message': 'Post created successfully! Your post is pending admin approval and will be visible once approved.'
            }, status=status.HTTP_201_CREATED, headers=headers)
        except Exception as e:
            print("Create Error:", str(e))
            print("=" * 50)
            return Response({
                'success': False,
                'message': f'Error creating post: {str(e)}'
            }, status=status.HTTP_400_BAD_REQUEST)
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Custom filtering
        sort_by = self.request.query_params.get('sort_by')
        if sort_by == 'funded':
            # Sort by funding percentage (raised/goal ratio)
            queryset = queryset.extra(
                select={'funding_ratio': 'raised / goal'},
                order_by=['-funding_ratio']
            )
        elif sort_by == 'newest':
            queryset = queryset.order_by('-created_at')
        elif sort_by == 'ending':
            # For now, just sort by goal amount (could add deadline field later)
            queryset = queryset.order_by('goal')
            
        return queryset

class RaiseUpPostDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = RaiseUpPost.objects.filter(is_active=True)
    serializer_class = RaiseUpPostSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    
    def get_permissions(self):
        if self.request.method in ['PUT', 'PATCH', 'DELETE']:
            return [IsAuthenticated()]
        return [IsAuthenticatedOrReadOnly()]
    
    def perform_update(self, serializer):
        # Only allow poster to update their own posts
        if serializer.instance.poster != self.request.user:
            raise PermissionError("You can only update your own posts")
        serializer.save()
    
    def perform_destroy(self, instance):
        # Only allow poster to delete their own posts
        if instance.poster != self.request.user:
            raise PermissionError("You can only delete your own posts")
        # Soft delete
        instance.is_active = False
        instance.save()

@api_view(['GET'])
def featured_posts(request):
    """Get featured raise-up posts for homepage carousel"""
    posts = RaiseUpPost.objects.filter(is_active=True, is_featured=True)[:6]
    serializer = RaiseUpPostSerializer(posts, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def post_stats(request):
    """Get overall statistics for raise-up posts"""
    total_posts = RaiseUpPost.objects.filter(is_active=True).count()
    total_raised = RaiseUpPost.objects.filter(is_active=True).aggregate(
        total=models.Sum('raised')
    )['total'] or 0
    
    return Response({
        'total_posts': total_posts,
        'total_raised': float(total_raised),
        'total_supporters': total_posts * 12  # Mock calculation
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def invest_in_post(request, post_id):
    """Investment endpoint with balance deduction"""
    try:
        from base.models import Balance
        
        post = RaiseUpPost.objects.get(id=post_id, is_active=True)
        amount = Decimal(str(request.data.get('amount', 0)))
        payment_method = request.data.get('payment_method', 'balance')
        
        if amount <= 0:
            return Response({
                'success': False,
                'message': 'Invalid amount'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # If paying with balance, deduct from user balance
        if payment_method == 'balance':
            user = request.user
            if user.balance < amount:
                return Response({
                    'success': False,
                    'message': 'Insufficient balance'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Create Balance transaction record for investment
            Balance.objects.create(
                user=request.user,
                amount=amount,
                payable_amount=amount,
                transaction_type='raise_up_investment',
                payment_method=payment_method,
                description=f'Investment in "{post.title}"',
                completed=True,
                approved=True,
                bank_status='completed'
            )
        
        # Create donation record (investments are tracked as donations)
        Donation.objects.create(
            post=post,
            user=request.user,
            amount=amount,
            payment_method=payment_method
        )
        
        # Update post raised amount
        post.raised += amount
        post.save()
        
        # Get top donator
        top_donation = post.donations.order_by('-amount').first()
        top_donator = None
        if top_donation:
            top_donator = {
                'name': top_donation.user.first_name or top_donation.user.username,
                'amount': float(top_donation.amount),
                'user_id': top_donation.user.id
            }
        
        return Response({
            'success': True,
            'message': f'Investment of ৳{amount} in "{post.title}" recorded',
            'post_id': post_id,
            'amount': amount,
            'new_balance': request.user.balance if payment_method == 'balance' else None,
            'post_raised': float(post.raised),
            'top_donator': top_donator
        })
    except RaiseUpPost.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Post not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def donate_to_post(request, post_id):
    """Donation endpoint with balance deduction"""
    try:
        from base.models import Balance
        
        post = RaiseUpPost.objects.get(id=post_id, is_active=True)
        amount = Decimal(str(request.data.get('amount', 0)))
        payment_method = request.data.get('payment_method', 'balance')
        
        if amount <= 0:
            return Response({
                'success': False,
                'message': 'Invalid amount'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # If paying with balance, deduct from user balance
        if payment_method == 'balance':
            user = request.user
            if user.balance < amount:
                return Response({
                    'success': False,
                    'message': 'Insufficient balance'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Create Balance transaction record for donation
            Balance.objects.create(
                user=request.user,
                amount=amount,
                payable_amount=amount,
                transaction_type='raise_up_donation',
                payment_method=payment_method,
                description=f'Donation to "{post.title}"',
                completed=True,
                approved=True,
                bank_status='completed'
            )
        
        # Create donation record
        Donation.objects.create(
            post=post,
            user=request.user,
            amount=amount,
            payment_method=payment_method
        )
        
        # Update post raised amount
        post.raised += amount
        post.save()
        
        # Get top donator
        top_donation = post.donations.order_by('-amount').first()
        top_donator = None
        if top_donation:
            top_donator = {
                'name': top_donation.user.first_name or top_donation.user.username,
                'amount': float(top_donation.amount),
                'user_id': top_donation.user.id
            }
        
        return Response({
            'success': True,
            'message': f'Donation of ৳{amount} to "{post.title}" recorded',
            'post_id': post_id,
            'amount': amount,
            'new_balance': request.user.balance if payment_method == 'balance' else None,
            'post_raised': float(post.raised),
            'top_donator': top_donator
        })
    except RaiseUpPost.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Post not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_post_donations(request, post_id):
    """Get all donations for a post with pagination"""
    try:
        from django.core.paginator import Paginator
        
        print(f"Fetching donations for post_id: {post_id}")
        post = RaiseUpPost.objects.get(id=post_id, is_active=True)
        donations = post.donations.select_related('user').order_by('-amount', '-created_at')
        print(f"Found {donations.count()} donations")
        
        # Pagination
        page = int(request.GET.get('page', 1))
        page_size = int(request.GET.get('page_size', 10))
        
        paginator = Paginator(donations, page_size)
        page_obj = paginator.get_page(page)
        
        donations_list = []
        for donation in page_obj:
            donations_list.append({
                'user_name': donation.user.first_name or donation.user.username,
                'amount': float(donation.amount),
                'created_at': donation.created_at.strftime('%b %d, %Y'),
                'payment_method': donation.payment_method,
                'user_id': donation.user.id
            })
        
        return Response({
            'success': True,
            'donations': donations_list,
            'total_donations': paginator.count,
            'current_page': page,
            'total_pages': paginator.num_pages,
            'has_next': page_obj.has_next(),
            'has_previous': page_obj.has_previous()
        })
    except RaiseUpPost.DoesNotExist:
        print(f"Post not found: {post_id}")
        return Response({
            'success': False,
            'message': 'Post not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        import traceback
        print(f"Error in get_post_donations: {str(e)}")
        print(traceback.format_exc())
        return Response({
            'success': False,
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
