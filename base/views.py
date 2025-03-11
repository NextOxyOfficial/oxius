from django.shortcuts import render
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import generics
from .models import *
from .serializers import *
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import AllowAny
from rest_framework.decorators import permission_classes, api_view
from rest_framework.exceptions import NotFound
import base64
from io import BytesIO
from django.core.files.base import ContentFile
from django.shortcuts import get_object_or_404
from django.db.models import Q
from uuid import UUID
from decimal import Decimal
from rest_framework.pagination import PageNumberPagination
from random import shuffle
import requests
from django.conf import settings

from django.core.mail import send_mail
from rest_framework.authtoken.models import Token
from django.contrib.auth.hashers import make_password

# Create your views here.


# move this function to util later
def base64ToFile(base64_data):
    # Remove the prefix if it exists (e.g., "data:image/png;base64,")
    if base64_data.startswith('data:image'):
        base64_data = base64_data.split('base64,')[1]
    
    # Decode the Base64 string into bytes
    file_data = base64.b64decode(base64_data)
    
    # Create a Django ContentFile object from the bytes
    file = ContentFile(file_data)
    
    # You can create a filename, e.g., using the current timestamp or other logic
    filename = "uploaded_image.png"  # Customize as needed
    
    # Save the file to the appropriate storage (e.g., media directory)
    file.name = filename
    return file


@api_view(["GET"])
def getLogo(request):
    logo = get_object_or_404(Logo)
    serializer = logoSerializer(logo)
    return Response(serializer.data)

@api_view(["GET"])
def getAuthenticationBanner(request):
    banner = get_object_or_404(AuthenticationBanner)
    serializer = AuthenticationBannerSerializer(banner)
    return Response(serializer.data)

@api_view(["GET"])
def getAdminNotice(request):
    serializer = AdminNoticeSerializer(AdminNotice.objects.all(),many=True)
    return Response(serializer.data)

@api_view(['POST'])
def register(request):
    data = request.data
    
    # Check if user with phone or email already exists
    if User.objects.filter(phone=data.get('phone')).exists():
        return Response(
            {'error': 'User with this phone number already exists'},
            status=status.HTTP_400_BAD_REQUEST
        )
        
    if User.objects.filter(email=data.get('email')).exists():
        return Response(
            {'error': 'User with this email already exists'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Handle referral
    ref_by = None
    if 'refer' in data:
        ref_by = User.objects.filter(referral_code=data['refer']).first()
        del data['refer']
    if 'image' in data:
        try:
            data['image'] = base64ToFile(data['image'])
        except Exception as e:
            return Response(
                {'message': 'Failed to process image', 'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    serializer = UserSerializer(data=data)
    if serializer.is_valid():
        new_user = serializer.save()
        if ref_by:
            new_user.refer = ref_by
            new_user.save()
            ref_by.refer_count += 1
            ref_by.save()
        return Response(
            {'message': 'Person registered successfully', 'data': serializer.data},
            status=status.HTTP_201_CREATED
        )
    print(serializer.errors)
    return Response(
        {'message': 'Validation failed', 'errors': serializer.errors},
        status=status.HTTP_400_BAD_REQUEST
    )


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_user(request, email):
    data = request.data
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response(
            {'message': 'User not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    # Remove email from data if it's unchanged
    if 'email' in data and data['email'] == user.email:
        data.pop('email')

    if 'image' in data:
        try:
            data['image'] = base64ToFile(data['image'])
        except Exception as e:
            return Response(
                {'message': 'Failed to process image', 'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
        
    data['id'] = user.id
    serializer = UserSerializer(user, data=data, partial=True)

    if serializer.is_valid():
        try:
            user.save()  # Save any direct changes to the user instance
            serializer.save()  # Save changes from the serializer
            return Response(
                {'message': 'User updated successfully', 'data': serializer.data},
                status=status.HTTP_200_OK
            )
        except Exception as e:
            return Response(
                {'message': 'Failed to save user', 'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    print(serializer.errors)
    # Return validation errors if serializer is not valid
    return Response(
        {'message': 'Validation failed', 'errors': serializer.errors},
        status=status.HTTP_400_BAD_REQUEST
    )

# @api_view(['GET', 'POST'])
# def update_user(request):
#     """
#     List all code snippets, or create a new snippet.
#     """
#     if request.method == 'GET':
#         snippets = Snippet.objects.all()
#         serializer = SnippetSerializer(snippets, many=True)
#         return Response(serializer.data)

#     elif request.method == 'POST':
#         serializer = SnippetSerializer(data=request.data)
#         if serializer.is_valid():
#             serializer.save()
#             return Response(serializer.data, status=status.HTTP_201_CREATED)
#         return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_nid(request):
    try:
        nid = NID.objects.get(user=request.user)
        
        serializer = NIDSerializer(nid)
        print(nid)
        return Response(
            {'message': 'NID details retrieved successfully', 'data': serializer.data},
            status=status.HTTP_200_OK
        )
    except NID.DoesNotExist:
        return Response(
            {'message': 'NID not found for the user'},
            status=status.HTTP_404_NOT_FOUND
        )
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_nid(request):
    data = request.data
    data['user'] = request.user.id
    fields_to_process = ['front', 'back', 'selfie', 'other_document']
    for field in fields_to_process:
        if field in data and  data[field] not in [None, "", "null"]:
            try:
                data[field] = base64ToFile(data[field])
            except Exception as e:
                return Response(
                    {'message': f'Failed to process {field} image', 'error': str(e)},
                    status=status.HTTP_400_BAD_REQUEST
                )
    serializer = NIDSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return Response(
            {'message': 'NID Added successfully', 'data': serializer.data},
            status=status.HTTP_200_OK)
    print(serializer.errors)
    return Response(
            {'message': 'Failed to add NID', 'errors': serializer.errors},
            status=status.HTTP_400_BAD_REQUEST
        )

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_nid(request):
    try:
        nid = NID.objects.get(user=request.user)
    except NID.DoesNotExist:
        return Response(
            {'message': 'NID not found for the user'},
            status=status.HTTP_404_NOT_FOUND
        )

    data = request.data
    if 'front' in data:
        try:
            data['front'] = base64ToFile(data['front'])
        except Exception as e:
            return Response(
                {'message': 'Failed to process front image', 'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    if 'back' in data:
        try:
            data['back'] = base64ToFile(data['back'])
        except Exception as e:
            return Response(
                {'message': 'Failed to process back image', 'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

    serializer = NIDSerializer(nid, data=data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(
            {'message': 'NID updated successfully', 'data': serializer.data},
            status=status.HTTP_200_OK
        )
    return Response(
        {'message': 'Failed to update NID', 'errors': serializer.errors},
        status=status.HTTP_400_BAD_REQUEST
    )



class PersonRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer

    def get_object(self):
        email = self.kwargs.get('email')
        try:
            return User.objects.get(email=email)
        except User.DoesNotExist:
            raise NotFound({"error": f"No person found with email: {email}"})
@api_view(['GET'])
def get_user_with_identifier(request, identifier):
    print(identifier)
    try:
        user = User.objects.get(Q(email=identifier) | Q(phone=identifier))
        return Response({
            "id": user.id,
            "email": user.email,
            "phone": user.phone,
            "name":user.name  # Include additional fields as needed
        })
    except User.DoesNotExist:
        raise NotFound({"error": f"No person found with email or phone: {identifier}"})

class ClassifiedCategoryPagination(PageNumberPagination):
    page_size = 14
    # def get_page_size(self, request):
    #     if request.query_params.get(self.page_query_param) in [None, '', '1']:
    #         return 14
    #     return self.page_size

class GetClassifiedCategories(generics.ListCreateAPIView):
    queryset = ClassifiedCategory.objects.all().order_by('title')
    serializer_class = ClassifiedServicesSerializer
    permission_classes = [AllowAny]
    pagination_class = ClassifiedCategoryPagination
    def get_queryset(self):
        """
        Optionally filter the queryset by title.
        """
        queryset = super().get_queryset()
        title = self.request.query_params.get('title', None)
        if title:
            queryset = queryset.filter(title__icontains=title)
        return queryset
    def get(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        paginator = self.pagination_class()
        paginated_queryset = paginator.paginate_queryset(queryset, request)
        serializer = self.get_serializer(paginated_queryset, many=True)
        return paginator.get_paginated_response(serializer.data)

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class GetClassifiedCategoriesAll(generics.ListCreateAPIView):
    queryset = ClassifiedCategory.objects.all().order_by('title')
    serializer_class = ClassifiedServicesSerializer
    permission_classes = [AllowAny]
    
    
class GetMicroGigs(generics.ListCreateAPIView):
    serializer_class = MicroGigPostSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = MicroGigPost.objects.exclude(
            gig_status__in=['pending', 'rejected', 'completed']
        )
        
        # Get category from query params
        category = self.request.query_params.get('category', None)
        show_submitted = self.request.query_params.get('show_submitted', None)
        show_all = self.request.query_params.get('show_all', None)
        user = self.request.user

        if category:
            queryset = queryset.filter(category=category)
        
        if user.is_authenticated and show_all != 'true':
            if show_submitted == 'true':
                # Show only gigs where user has submitted tasks
                queryset = queryset.filter(
                    microgigposttask__user=user
                ).distinct()
            elif show_submitted == 'false':
                # Show only gigs where user hasn't submitted tasks
                queryset = queryset.exclude(
                    microgigposttask__user=user
                )
            else:
                # Default: Show only gigs where user hasn't submitted tasks
                queryset = queryset.exclude(
                    microgigposttask__user=user
                )
        
        return queryset.order_by('-created_at')
    
    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


# Micro Gig Post
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def post_micro_gigs(request):
    data = request.data # Make a mutable copy of the data
    user=request.user
    data['user'] = user.id  # Associate the authenticated user
    serializer = MicroGigPostSerializer(data=data)
    if serializer.is_valid():
        if user.balance < data['total_cost']:
            # raise ValueError("Insufficient balance")
            return Response(
        {'message': 'Insufficient balance', 'errors': 'Insufficient balance'},
        status=status.HTTP_400_BAD_REQUEST
    )
        user.balance -= Decimal(data['total_cost'])
        user.save()
        new_micro_gig_post = serializer.save(user=user)
        for file in data['medias']:
            nm = MicroGigPostMedia.objects.create(
                image = base64ToFile(file)
            )
            new_micro_gig_post.medias.add(nm)
        return Response(
            {'message': 'Person Updated successfully', 'data': serializer.data},
            status=status.HTTP_201_CREATED
        )
    if serializer.errors:
        print(serializer.errors)    
    return Response(
        {'message': 'Validation failed', 'errors': serializer.errors},
        status=status.HTTP_400_BAD_REQUEST
    )

# Micro Gig Put Update
@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_micro_gig_post(request, pk):
    try:
        micro_gig_post = get_object_or_404(MicroGigPost, id=pk)
        
        # Check if the user is the owner or a superuser
        if request.user == micro_gig_post.user or request.user.is_superuser:
            additional_cost = Decimal(request.data.get('additional_cost', 0))

            # Ensure the user has enough balance for the additional cost
            if request.user.balance < additional_cost:
                return Response(
                    {'message': 'Insufficient balance', 'errors': 'Insufficient balance'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Deduct additional cost from user balance
            request.user.balance -= additional_cost
            request.user.save()
            print(micro_gig_post.total_cost + additional_cost)
            # Adjust balance and quantity in micro_gig_post
            micro_gig_post.total_cost = micro_gig_post.total_cost + additional_cost
            micro_gig_post.balance += Decimal(request.data.get('balance', 0))
            micro_gig_post.required_quantity += int(request.data.get('required_quantity', 0))
            
            # Update the MicroGigPost using serializer
            serializer = MicroGigPostSerializer(micro_gig_post, data=request.data, partial=True)
            if serializer.is_valid():
                try:
                    serializer.save()
                    return Response(serializer.data, status=status.HTTP_200_OK)
                except ValidationError as e:
                    # Return the validation error message from the model
                    return Response(
                        {"error": str(e)},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            else:
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        else:
            return Response({"error": "You are not authorized to update this post."}, status=status.HTTP_403_FORBIDDEN)
    
    except ValidationError as e:
        # Handle any validation errors that might occur outside the serializer.save()
        return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
    except MicroGigPost.DoesNotExist:
        return Response({"error": "MicroGigPost not found."}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        # Log the error for debugging
        print(f"Unexpected error in update_micro_gig_post: {str(e)}")
        return Response({"error": "Can't stop the gig. You have pending tasks"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def post_classified_service(request):
    data = request.data.copy()  # Make a mutable copy of the data
    data['user'] = request.user.id  # Associate the authenticated user
    category_id = data.get('category')
    if not ClassifiedCategory.objects.filter(id=category_id).exists():
        raise ValidationError({'category': 'The specified category does not exist.'})
    serializer = ClassifiedPostSerializer(data=data)
    
    if serializer.is_valid():
        new_classified_service_post = serializer.save(user=request.user)
        for file in data.get('medias', []):
            nm = ClassifiedCategoryPostMedia.objects.create(image=base64ToFile(file))
            new_classified_service_post.medias.add(nm)
        
        return Response(
            {'message': 'Person Updated successfully', 'data': serializer.data},
            status=status.HTTP_201_CREATED
        )
    print(serializer.errors)    
    return Response(
        {'message': 'Validation failed', 'errors': serializer.errors},
        status=status.HTTP_400_BAD_REQUEST
    )

class ClassifiedPostPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100

class GetClassifiedPosts(generics.ListAPIView):
    serializer_class = ClassifiedPostSerializer
    pagination_class = ClassifiedPostPagination
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = ClassifiedCategoryPost.objects.filter(
            service_status='approved'
        ).select_related(
            'category'     
        ).defer(
        'user'  # Tell Django not to load the user field
    ).order_by('-created_at')
        
        title = self.request.query_params.get('title', None)
        
        if title:
            queryset = queryset.filter(
                Q(title__icontains=title) |
                Q(instructions__icontains=title)
            )
        
        return queryset

class ClassifiedCategoryPostFilterView(APIView):
    def get(self, request):
        country = request.GET.get('country')
        state = request.GET.get('state')
        city = request.GET.get('city')
        upazila = request.GET.get('upazila')
        category = request.GET.get('category')
        title = request.GET.get('title')

        # Filter based on the query parameters
        filters = Q()
        if category:
            filters &= Q(category__id=category)
        if title:
            filters &= Q(title__icontains=title)
        if country:
            filters &= Q(country__iexact=country)
        if state:
            filters &= Q(state__iexact=state)
        if city:
            filters &= Q(city__iexact=city)
        if upazila:
            filters &= Q(upazila__iexact=upazila)
        

        posts = ClassifiedCategoryPost.objects.filter(filters)

        print(posts)
        serializer = ClassifiedPostSerializer(posts, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

@api_view(['GET'])
def classifiedCategoryPosts(request, cid):
    posts = list(ClassifiedCategoryPost.objects.filter(category=cid))
    # for random category posts
    shuffle(posts)
    serializer = ClassifiedPostSerializer(posts, many=True)
    
    # serializer = ClassifiedPostSerializer(ClassifiedCategoryPost.objects.filter(category=cid).order_by('-created_at'),many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)
    


@api_view(['GET'])
def UserClassifiedCategoryPosts(request):
    # Get the logged-in user
    user = request.user

    # Filter posts by category and user
    posts = ClassifiedCategoryPost.objects.filter( user=user).order_by('title')

    # Serialize the filtered posts
    serializer = ClassifiedPostSerializer(posts, many=True)

    return Response(serializer.data, status=status.HTTP_200_OK)

@api_view(['GET'])
def classifiedCategoryPost(request, pk):
    serializer = ClassifiedPostSerializer(ClassifiedCategoryPost.objects.get(id=pk))
    return Response(serializer.data, status=status.HTTP_200_OK)

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_classified_post(request, pk):
    print("User:", request.user)
    print("Is authenticated:", request.user.is_authenticated)
    print("Is superuser:", request.user.is_superuser)
    try:
        classified_post = get_object_or_404(ClassifiedCategoryPost, id=pk)
        
        # Check if the user is the owner or a superuser
        if request.user == classified_post.user or request.user.is_superuser:
            serializer = ClassifiedPostSerializer(classified_post, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data, status=status.HTTP_200_OK)
            else:
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        else:
            return Response({"error": "You are not authorized to update this post."}, status=status.HTTP_403_FORBIDDEN)
    
    except ClassifiedCategoryPost.DoesNotExist:
        return Response({"error": "ClassifiedCategoryPost not found."}, status=status.HTTP_404_NOT_FOUND)

# Classified Post Delete
@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_classified_post(request, pk):
    try:
        classified_post = get_object_or_404(ClassifiedCategoryPost, id=pk)
        
        # Check if the user is the owner or a superuser
        if request.user == classified_post.user or request.user.is_superuser:
            classified_post.delete()
            return Response({"message": "ClassifiedCategoryPost deleted successfully."}, status=status.HTTP_200_OK)
        else:
            return Response({"error": "You are not authorized to delete this post."}, status=status.HTTP_403_FORBIDDEN)
    
    except ClassifiedCategoryPost.DoesNotExist:
        return Response({"error": "ClassifiedCategoryPost not found."}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
def gigDetails(request, gid):
    serializer = MicroGigPostDetailsSerializer(MicroGigPost.objects.get(id=gid))
    return Response(serializer.data, status=status.HTTP_200_OK)


# All Micro Gig Post
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getUserMicroGigs(request, pk):
    # Order completed gigs to appear at the bottom
    queryset = MicroGigPost.objects.filter(user=pk).order_by(
        # This puts non-completed gigs first, then completed ones
        models.Case(
            models.When(gig_status='completed', then=1),
            default=0
        ),
        '-created_at'  # Within each group, show newest first
    )
    
    serializer = MicroGigPostSerializer(queryset, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)

# Micro Gig Post
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_micro_gig_post(request,pk):
    serializer = MicroGigPostSerializer(MicroGigPost.objects.get(id=pk))
    return Response(serializer.data, status=status.HTTP_200_OK)




# Micro Gig Post Delete
@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_micro_gig_post(request, pk):
    try:
        micro_gig_post = get_object_or_404(MicroGigPost, id=pk)
        
        # Check if the user is the owner or a superuser
        if request.user == micro_gig_post.user or request.user.is_superuser:
            micro_gig_post.delete()
            return Response({"message": "MicroGigPost deleted successfully."}, status=status.HTTP_200_OK)
        else:
            return Response({"error": "You are not authorized to delete this post."}, status=status.HTTP_403_FORBIDDEN)
    
    except MicroGigPost.DoesNotExist:
        return Response({"error": "MicroGigPost not found."}, status=status.HTTP_404_NOT_FOUND)

# Micro Gig Post Task
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getMicroGigPostTasks(request,email):
    serializer = MicroGigPostTaskSerializer(MicroGigPostTask.objects.filter(user=email), many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def postMicroGigPostTask(request):
    data = request.data.copy()
    data['user'] = request.user.id
    gig_id = data.get('gig')

    # Check if user has already submitted a task for this gig
    existing_task = MicroGigPostTask.objects.filter(
        user=request.user,
        gig_id=gig_id
    ).exists()

    if existing_task:
        return Response({
            "error": "You have already submitted a task for this gig"
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # If no existing task, proceed with creation
    serializer = MicroGigPostTaskSerializer(data=data)
    if serializer.is_valid():
        new_micro_gig_post_task = serializer.save(user=request.user)
        
        # Handle medias
        for file in data.get('medias', []):
            nm = MicroGigPostMedia.objects.create(image=base64ToFile(file))
            new_micro_gig_post_task.medias.add(nm)
        
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

  
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getPendingTasks(request):
    serializer = GetMicroGigPostTaskSerializer(MicroGigPostTask.objects.filter(user=request.user).order_by('-created_at'), many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)




@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_microgigpost_tasks(request, gig_id):
    """
    Retrieve all tasks associated with a specific MicroGigPost.
    """
    try:
        # Retrieve the MicroGigPost instance
        micro_gig_post = MicroGigPost.objects.get(id=gig_id)
    except MicroGigPost.DoesNotExist:
        return Response(
            {"error": "MicroGigPost not found"},
            status=status.HTTP_404_NOT_FOUND
        )

    # Get all tasks associated with this MicroGigPost
    tasks = micro_gig_post.microgigposttask_set.all().order_by(
        models.Case(
            # Order: pending (not approved and not rejected) first, then approved, then rejected
            models.When(approved=True, then=1),
            models.When(rejected=True, then=2),
            default=0  # Pending tasks
        ),
        '-created_at'  # Then by creation date (newest first)
    )

    # Serialize the tasks
    serializer = GetMicroGigPostTaskSerializer(tasks, many=True)

    return Response(serializer.data, status=status.HTTP_200_OK)

# Single Task Approve / Reject
# @api_view(['PUT'])
# @permission_classes([IsAuthenticated])
# def update_microgigpost_tasks(request, gig_id):
#     try:
#         # Retrieve the MicroGigPost instance
#         micro_gig_post = MicroGigPost.objects.get(id=gig_id)
#     except MicroGigPost.DoesNotExist:
#         return Response(
#             {"error": "MicroGigPost not found"},
#             status=status.HTTP_404_NOT_FOUND
#         )

#     # Retrieve the tasks related to this MicroGigPost
#     tasks = micro_gig_post.microgigposttask_set.all()

#     # Validate and update each task
#     data = request.data.get('tasks', [])
#     if not isinstance(data, list):
#         return Response(
#             {"error": "Expected a list of tasks in 'tasks' field."},
#             status=status.HTTP_400_BAD_REQUEST
#         )

#     # Create a list to track updated tasks
#     updated_tasks = []

#     for task_data in data:
#         task_id = task_data.get('id')
#         if not task_id:
#             return Response(
#                 {"error": "Task 'id' is required for updates."},
#                 status=status.HTTP_400_BAD_REQUEST
#             )
#         try:
#             # Get the task instance
#             task = tasks.get(id=task_id)
#         except MicroGigPostTask.DoesNotExist:
#             return Response(
#                 {"error": f"Task with id {task_id} not found."},
#                 status=status.HTTP_404_NOT_FOUND
#             )

#         # Serialize the task data and validate
#         serializer = GetMicroGigPostTaskSerializer(task, data=task_data, partial=True)
#         if serializer.is_valid():
#             # Save the updated task
#             serializer.save()
#             updated_tasks.append(serializer.data)
#         else:
#             return Response(
#                 {"error": f"Invalid data for task with id {task_id}.", "details": serializer.errors},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#     return Response({"updated_tasks": updated_tasks}, status=status.HTTP_200_OK)

# @api_view(['PUT'])
# @permission_classes([IsAuthenticated])
# def update_microgigpost_tasks(request, gig_id):
#     """
#     Update tasks associated with a specific MicroGigPost.
#     Handles both individual task updates and bulk approvals.
#     """
#     try:
#         # Retrieve the MicroGigPost instance
#         micro_gig_post = MicroGigPost.objects.get(id=gig_id)
        
#         # Check authorization - only gig owner or admin can update tasks
#         if request.user != micro_gig_post.user and not request.user.is_staff:
#             return Response(
#                 {"error": "You don't have permission to update tasks for this gig"},
#                 status=status.HTTP_403_FORBIDDEN
#             )
            
#     except MicroGigPost.DoesNotExist:
#         return Response(
#             {"error": "MicroGigPost not found"},
#             status=status.HTTP_404_NOT_FOUND
#         )

#     # Get the tasks data from request
#     tasks_data = request.data.get('tasks')
#     print(tasks_data)
#     if not tasks_data:
#         return Response(
#             {"error": "No tasks provided in the request"},
#             status=status.HTTP_400_BAD_REQUEST
#         )
        
#     if not isinstance(tasks_data, list):
#         return Response(
#             {"error": "Expected a list of tasks in 'tasks' field"},
#             status=status.HTTP_400_BAD_REQUEST
#         )

#     updated_tasks = []
#     errors = []

#     # Validate all task IDs before making any changes
#     for index, task_data in enumerate(tasks_data):
#         if not task_data.get('id'):
#             errors.append({
#                 "index": index,
#                 "error": "Task ID is required"
#             })
    
#     if errors:
#         return Response(
#             {"errors": errors},
#             status=status.HTTP_400_BAD_REQUEST
#         )

#     # Process each task update
#     try:
#         for task_data in tasks_data:
#             task_id = task_data.get('id')
#             try:
#                 task = MicroGigPostTask.objects.get(id=task_id, gig=micro_gig_post)
                
#                 # Handle the update based on the task data
#                 if 'approved' in task_data:
#                     task.approved = task_data['approved']
#                     if task_data['approved']:
#                         task.rejected = False
#                 elif 'rejected' in task_data:
#                     task.rejected = task_data['rejected']
#                     if task_data['rejected']:
#                         task.approved = False
#                         if task_data.get('reason'):
#                             task.reason = task_data['reason']

#                 # Save the task
#                 task.save()
                
#                 # Serialize the updated task
#                 serializer = GetMicroGigPostTaskSerializer(task)
#                 updated_tasks.append(serializer.data)

#             except MicroGigPostTask.DoesNotExist:
#                 errors.append({
#                     "task_id": task_id,
#                     "error": f"Task not found or doesn't belong to this gig"
#                 })

#         if errors:
#             return Response(
#                 {"message": "Some tasks could not be updated", "errors": errors},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         return Response({
#             "message": "Tasks updated successfully",
#             "updated_tasks": updated_tasks
#         }, status=status.HTTP_200_OK)
        
#     except Exception as e:
#         return Response({
#             "error": "An error occurred while updating tasks",
#             "detail": str(e)
#         }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_microgigpost_tasks(request, gig_id):
    try:
        micro_gig_post = MicroGigPost.objects.get(id=gig_id)
        
        if request.user != micro_gig_post.user and not request.user.is_staff:
            return Response(
                {"error": "You don't have permission to update tasks for this gig"},
                status=status.HTTP_403_FORBIDDEN
            )
            
        tasks_data = request.data.get('tasks', [])
        if not tasks_data:
            return Response(
                {"error": "No tasks provided"},
                status=status.HTTP_400_BAD_REQUEST
            )

        updated_tasks = []
        for task_data in tasks_data:
            task_id = task_data.get('id')
            try:
                task = MicroGigPostTask.objects.get(id=task_id, gig=micro_gig_post)
                
                # Update task status
                if task_data.get('rejected'):
                    task.rejected = True
                    task.approved = False
                    task.reason = task_data.get('reason', '')  # Set rejection reason
                    # task.completed = True  # Mark as completed when rejected
                elif task_data.get('approved'):
                    task.approved = True
                    task.rejected = False
                    # task.completed = True  # Mark as completed when approved

                task.save()
                serializer = GetMicroGigPostTaskSerializer(task)
                updated_tasks.append(serializer.data)

            except MicroGigPostTask.DoesNotExist:
                return Response(
                    {"error": f"Task {task_id} not found"},
                    status=status.HTTP_404_NOT_FOUND
                )

        return Response({
            "message": "Tasks updated successfully",
            "updated_tasks": updated_tasks
        }, status=status.HTTP_200_OK)

    except MicroGigPost.DoesNotExist:
        return Response(
            {"error": "MicroGigPost not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        print(f"Error updating tasks: {str(e)}")  # Add logging
        return Response(
            {"error": "Server error occurred"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# class UserBalance(generics.ListCreateAPIView):
#     permission_classes = [IsAuthenticated]
#     serializer_class = BalanceSerializer
#     queryset = Balance.objects.all()
#     lookup_field = 'user'
class UserBalance(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = BalanceSerializer
    
    def get_queryset(self):
        # Filter balances by the logged-in user
        return Balance.objects.filter(user=self.request.user).order_by('-updated_at')
    

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def postBalance(request):
    # Add the user ID (pk) to the incoming data
    data = request.data.copy()
    data['user'] = request.user.id
    print(data)
    to_user = None
    

    # Check if 'merchant_invoice_no' exists in the data
    if 'merchant_invoice_no' in data:
        # Check if Balance with the given merchant_invoice_no exists
        if Balance.objects.filter(merchant_invoice_no=data['merchant_invoice_no']).exists():
            return Response(
                {"error": "Balance with this merchant invoice number already exists."},
                status=status.HTTP_400_BAD_REQUEST
            )
    # else:
    #     # Return an error if 'merchant_invoice_no' is missing
    #     return Response(
    #         {"error": "The 'merchant_invoice_no' field is required."},
    #         status=status.HTTP_400_BAD_REQUEST
    #     )
    
    # Proceed with the operations if 'merchant_invoice_no' is valid
    if 'contact' in data and data['contact']:
        to_user = User.objects.get(Q(email=data['contact']) | Q(phone=data['contact']))
        del data['contact']
    serializer = BalanceSerializer(data=data)
    
    if serializer.is_valid():
        # Save the new Balance instance
        new_b = serializer.save(user=request.user)
        if to_user:
            new_b.to_user = to_user
            new_b.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    # Print errors if validation fails
    print(serializer.errors)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



class AdminMessage(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = AdminNoticeSerializer
    def get_queryset(self):
        return AdminNotice.objects.all().order_by('-created_at')

class GetMicroGigCategory(generics.ListAPIView):
    queryset = MicroGigCategory.objects.all()
    serializer_class = MicroGigCategorySerializer
    permission_classes = [AllowAny]

class GetTargetNetwork(generics.ListAPIView):
    queryset = TargetNetwork.objects.all()
    serializer_class = TargetNetworkSerializer
    permission_classes = [AllowAny]

class GetTargetDevice(generics.ListAPIView):
    queryset = TargetDevice.objects.all()
    serializer_class = TargetDeviceSerializer
    permission_classes = [AllowAny]

class GetTargetCountry(generics.ListAPIView):
    queryset = TargetCountry.objects.all()
    serializer_class = TargetCountrySerializer
    permission_classes = [AllowAny]
    
    
class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
            return Response(serializer.validated_data, status=status.HTTP_200_OK)
        except Exception as e:
            # Extract error details
            error_message = serializer.errors.get("non_field_errors", ["Invalid credentials"])[0]
            return Response(
                {"error": error_message},
                status=status.HTTP_401_UNAUTHORIZED
            )


class TokenValidationView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def get(self, request):
        user = request.user

        # Generate tokens using Simple JWT
        refresh = RefreshToken.for_user(user)

        user_data = UserSerializerGet(user).data
        # Prepare the data to be returned
        data = {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': user_data
        }

        return Response(data)
    
@api_view(['GET'])
def get_faq(request):
    faqs = Faq.objects.all()
    serializer = FaqSerializer(faqs, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)




# @api_view(['GET'])
# def get_police_stations(request, district_id):
#     police_stations = PoliceStation.objects.filter(district=district_id)
#     serializer = PoliceStationSerializer(police_stations, many=True)
#     return Response(serializer.data, status=status.HTTP_200_OK)

from .police_stations import CITY_AREAS 
@api_view(['GET'])
def police_station(request):
    city = request.GET.get('city', '').strip().capitalize()  # Get city from query param, capitalize to match dictionary keys
    if not city:
        return Response({"error": "City name is required"}, status=400)
    
    areas = CITY_AREAS.get(city, [])  # Fetch areas for the specified city
    if not areas:
        return Response({"error": f"No areas found for city: {city}"}, status=404)
    
    return Response(data=areas)


# for frontend

def index(request, **args):
    return render(request, 'index.html')




@permission_classes([IsAuthenticated])
@api_view(['POST', 'GET'])
def smsSend(request):
    phone =  request.GET.get('phone')
    message = 'Welcome to AdsyClub.com! You can now connect people enjoy services around you and earn money by completing tasks. Thank you!'
    url = "http://api.smsinbd.com/sms-api/sendsms"
    payload = {
        'api_token' : settings.API_SMS,
        'senderid' : '8809617614969',
        'contact_number' : phone,
        'message' : message,
    }
    response = requests.get(url, params = payload)
    print(response.text)
    return Response(response.text, status=status.HTTP_200_OK)

import json
@api_view(['POST'])
def sendOTP(request):
    phone = request.data.get('phone')
    print(phone)
    
    if not phone:
        return Response({'error': 'Phone number is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(phone=phone)
    except User.DoesNotExist:
        return Response({'error': 'User with this phone number does not exist'}, status=status.HTTP_404_NOT_FOUND)
    
    user.otp = random.randint(10000, 99999)
    user.save()
    message = f'Your One Time Password is {user.otp}'
    url = "http://api.smsinbd.com/sms-api/sendsms"
    payload = {
        'api_token' : settings.API_SMS,
        'senderid' : '8809617614969',
        'contact_number' : phone,
        'message' : message,
    }
    response = requests.get(url, params=payload)
    try:
        response_data = response.json()  # Convert the response to a dictionary
    except json.JSONDecodeError:
        return Response({'error': 'Failed to parse response from SMS provider'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    if response_data.get('status') == 'success':
        return Response({
            'message': response_data.get('message', 'OTP sent successfully'),
            'smsid': response_data.get('smsid', 'N/A'),
            'sms_count': response_data.get('SmsCount', 'N/A'),
            'phone': phone,
        }, status=status.HTTP_200_OK)
    else:
        return Response({
            'error': response_data.get('message', 'Failed to send OTP')
        }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def verifyOTP(request):
    phone = request.data.get('phone')
    otp = request.data.get('otp')
    print(phone, otp)
    
    if not phone or not otp:
        return Response({'error': 'Phone number and OTP are required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(phone=phone)
    except User.DoesNotExist:
        return Response({'error': 'User with this phone number does not exist'}, status=status.HTTP_404_NOT_FOUND)
    
    if otp and str(user.otp) == str(otp):
        user.otp = "000000"  # Clear OTP after successful verification
        user.save()
        token, created = Token.objects.get_or_create(user=user)
        return Response({'message': 'OTP verified successfully', 'token': token.key}, status=status.HTTP_200_OK)
    else:
        return Response({'error': 'Invalid OTP'}, status=status.HTTP_400_BAD_REQUEST)


from django.contrib.auth.hashers import check_password
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    user = request.user
    old_password = request.data.get('old_password')
    new_password = request.data.get('new_password')
    print(old_password, new_password)
    # Validate input
    if not old_password or not new_password:
        return Response({
            'error': 'Both old password and new password are required'
        }, status=status.HTTP_400_BAD_REQUEST)

    # Check if old password is correct
    if not check_password(old_password, user.password):
        return Response({
            'error': 'Current password is incorrect'
        }, status=status.HTTP_400_BAD_REQUEST)

    # Set new password
    user.set_password(new_password)
    user.save()

    return Response({
        'message': 'Password changed successfully'
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
def resetPassword(request):
    token_key = request.data.get('token')
    new_password = request.data.get('new_password')

    if not token_key or not new_password:
        return Response({'error': 'Token and new password are required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        token = Token.objects.get(key=token_key)
        user = token.user
    except Token.DoesNotExist:
        return Response({'error': 'Invalid token'}, status=status.HTTP_400_BAD_REQUEST)
    
    user.password = make_password(new_password)
    user.save()
    token.delete()  # Invalidate token after password reset
    
    return Response({'message': 'Password changed successfully'}, status=status.HTTP_200_OK)

@api_view(['POST'])
def reset_password_request(request):
    method = request.data.get('method')
    value = request.data.get(method)
    
    try:
        user = User.objects.get(**{method: value})
        # Generate OTP
        otp = ''.join([str(random.randint(0, 9)) for _ in range(6)])
        user.otp = otp
        user.save()
        
        # Send OTP
        if method == 'email':
            send_mail(
                'Password Reset OTP',
                f'Your OTP for password reset is: {otp}',
                settings.DEFAULT_FROM_EMAIL,
                [value],
                fail_silently=False,
            )
        else:
            # Implement SMS sending logic here
            pass
            
        return Response({'detail': 'Reset instructions sent'})
    except User.DoesNotExist:
        return Response(
            {'detail': f'No user found with this {method}'}, 
            status=status.HTTP_404_NOT_FOUND
        )

@api_view(['POST'])
def verify_reset_otp(request):
    method = request.data.get('method')
    value = request.data.get(method)
    otp = request.data.get('otp')
    
    try:
        user = User.objects.get(**{method: value})
        if user.otp != otp:
            return Response(
                {'detail': 'Invalid OTP'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        return Response({'detail': 'OTP verified'})
    except User.DoesNotExist:
        return Response(
            {'detail': 'User not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )

@api_view(['POST'])
def set_new_password(request):
    method = request.data.get('method')
    value = request.data.get(method)
    otp = request.data.get('otp')
    password = request.data.get('password')
    
    try:
        user = User.objects.get(**{method: value})
        if user.otp != otp:
            return Response(
                {'detail': 'Invalid OTP'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user.set_password(password)
        user.otp = '000000'  # Reset OTP
        user.save()
        
        return Response({'detail': 'Password reset successfully'})
    except User.DoesNotExist:
        return Response(
            {'detail': 'User not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )
