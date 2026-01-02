from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status
from .models import ReferralRewardProgram, ReferralRewardClaim


@api_view(['GET'])
@permission_classes([AllowAny])
def get_active_program(request):
    """Get active referral reward program"""
    program = ReferralRewardProgram.get_active()
    
    if not program:
        return Response({'active': False})
    
    banner_url = None
    if program.banner_image:
        banner_url = request.build_absolute_uri(program.banner_image.url)
    
    return Response({
        'active': True,
        'program': {
            'id': program.id,
            'name': program.name,
            'referrer_reward': float(program.referrer_reward),
            'referee_reward': float(program.referee_reward),
            'description': program.description,
            'banner_image': banner_url,
            'start_date': program.start_date.isoformat() if program.start_date else None,
            'end_date': program.end_date.isoformat() if program.end_date else None,
        }
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_my_claims(request):
    """Get user's reward claims with condition status"""
    from base.models import User

    program = ReferralRewardProgram.get_active()
    
    if not program:
        return Response({'active_program': False, 'claims': []})
    
    referred_users = User.objects.filter(refer=request.user)
    for referred_user in referred_users:
        claim, _ = ReferralRewardClaim.objects.get_or_create(
            program=program,
            user=request.user,
            claim_type='referrer',
            referred_user=referred_user,
            defaults={'reward_amount': program.referrer_reward},
        )
        if claim.reward_amount != program.referrer_reward:
            claim.reward_amount = program.referrer_reward
            claim.save(update_fields=['reward_amount'])

    claims = ReferralRewardClaim.objects.filter(user=request.user, program=program)
    
    claims_data = []
    for claim in claims:
        claim.check_conditions()
        referred_user_payload = None
        if claim.referred_user:
            referred_user_payload = {
                'id': str(claim.referred_user.id),
                'name': (f"{claim.referred_user.first_name} {claim.referred_user.last_name}").strip()
                if claim.referred_user.first_name
                else (claim.referred_user.name or claim.referred_user.username),
            }

        claims_data.append({
            'id': claim.id,
            'claim_type': claim.claim_type,
            'status': claim.status,
            'reward_amount': float(claim.reward_amount),
            'referred_user': referred_user_payload,
            'conditions': {
                'has_posted_bn': claim.has_posted_bn,
                'has_completed_microgig': claim.has_completed_microgig,
                'has_kyc_verified': claim.has_kyc_verified,
            },
            'all_met': claim.has_posted_bn and claim.has_completed_microgig and claim.has_kyc_verified,
            'claimed_at': claim.claimed_at.isoformat() if claim.claimed_at else None,
        })
    
    return Response({
        'active_program': True,
        'program': {
            'name': program.name,
            'referrer_reward': float(program.referrer_reward),
            'referee_reward': float(program.referee_reward),
        },
        'claims': claims_data,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def check_conditions(request):
    """Check user's progress on reward conditions"""
    from business_network.models import BusinessNetworkPost
    from base.models import MicroGigPostTask
    
    user = request.user
    program = ReferralRewardProgram.get_active()
    
    has_posted_bn = BusinessNetworkPost.objects.filter(author=user).exists()
    has_completed_microgig = MicroGigPostTask.objects.filter(user=user, approved=True).exists()
    has_kyc_verified = user.kyc
    
    # Get or create claim for referee if user was referred
    referee_claim = None
    if program and user.refer:
        referee_claim, created = ReferralRewardClaim.objects.get_or_create(
            program=program, user=user, claim_type='referee',
            defaults={'reward_amount': program.referee_reward}
        )
        referee_claim.check_conditions()
    
    return Response({
        'conditions': {
            'has_posted_bn': has_posted_bn,
            'has_completed_microgig': has_completed_microgig,
            'has_kyc_verified': has_kyc_verified,
            'all_met': has_posted_bn and has_completed_microgig and has_kyc_verified,
        },
        'reward_info': {
            'is_referee': user.refer is not None,
            'referrer_name': user.refer.first_name or user.refer.username if user.refer else None,
            'reward_amount': float(program.referee_reward) if program else 0,
            'claim_status': referee_claim.status if referee_claim else None,
        } if program else None,
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def claim_reward(request, claim_id):
    """Claim a specific reward"""
    try:
        claim = ReferralRewardClaim.objects.get(id=claim_id, user=request.user)
    except ReferralRewardClaim.DoesNotExist:
        return Response({'success': False, 'message': 'Claim not found'}, status=404)
    
    claim.check_conditions()
    success, message = claim.claim_reward()
    
    return Response({
        'success': success,
        'message': message,
        'new_balance': float(request.user.balance) if success else None,
    }, status=200 if success else 400)
