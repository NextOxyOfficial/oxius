from django.shortcuts import render
from rest_framework import status
from rest_framework.response import Response
from rest_framework import generics
from .models import *
from .serializers import *
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import AllowAny
from rest_framework.decorators import permission_classes, api_view
from rest_framework.exceptions import NotFound
import base64
from io import BytesIO
from django.core.files.base import ContentFile
from django.shortcuts import get_object_or_404

# Create your views here.


@api_view(["GET"])
def getLogo(request):
    serializer = logoSerializer(Logo.objects.get())
    return Response(serializer.data)

@api_view(["GET"])
def getAdminNotice(request):
    serializer = AdminNoticeSerializer(AdminNotice.objects.all(),many=True)
    return Response(serializer.data)

@api_view(['POST'])
def register(request):
    """
    Handles the registration of a new user.
    """
    serializer = UserSerializer(data=request.data)

    if serializer.is_valid():
        serializer.save()
        return Response(
            {'message': 'Person registered successfully', 'data': serializer.data},
            status=status.HTTP_201_CREATED
        )

    return Response(
        {'message': 'Validation failed', 'errors': serializer.errors},
        status=status.HTTP_400_BAD_REQUEST
    )

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_user(request,email):
    print(request.data)
    data = request.data
    data['id'] = request.user.id
    serializer = UserSerializer(User.objects.get(email=email),data=data)

    if serializer.is_valid():
        serializer.save()
        
        return Response(
            {'message': 'Person Updated successfully', 'data': serializer.data},
            status=status.HTTP_201_CREATED
        )
    print(serializer.errors)    
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

class PersonRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer

    def get_object(self):
        email = self.kwargs.get('email')
        try:
            return User.objects.get(email=email)
        except User.DoesNotExist:
            raise NotFound({"error": f"No person found with email: {email}"})

class GetClassifiedCategories(generics.ListCreateAPIView):
    queryset = ClassifiedCategory.objects.filter().order_by('-created_at')
    serializer_class = ClassifiedServicesSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        # data = {
        #     "message": "Product details fetched successfully",
        #     "data": serializer.data,
        # }
        return Response(serializer.data, status=status.HTTP_200_OK)
    
class GetMicroGigs(generics.ListCreateAPIView):
    queryset = MicroGigPost.objects.filter().order_by('-created_at')
    serializer_class = MicroGigPostSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

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

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def post_micro_gigs(request):
    data = request.data # Make a mutable copy of the data
    data['user'] = request.user.id  # Associate the authenticated user
    serializer = MicroGigPostSerializer(data=data)
    if serializer.is_valid():
        new_micro_gig_post = serializer.save(user=request.user)

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


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def post_classified_service(request):
    print(request.user)
    data = request.data.copy()  # Make a mutable copy of the data
    data['user'] = request.user.id  # Associate the authenticated user
    category_id = data.get('category')
    if not ClassifiedCategory.objects.filter(id=category_id).exists():
        raise ValidationError({'category': 'The specified category does not exist.'})
    serializer = ClassifiedPostSerializer(data=data)
    print(data)

    if serializer.is_valid():
        serializer.save(user=request.user)
        
        return Response(
            {'message': 'Person Updated successfully', 'data': serializer.data},
            status=status.HTTP_201_CREATED
        )
    print(serializer.errors)    
    return Response(
        {'message': 'Validation failed', 'errors': serializer.errors},
        status=status.HTTP_400_BAD_REQUEST
    )

@api_view(['GET'])
def classifiedCategoryPosts(request, cid):
    serializer = ClassifiedPostSerializer(ClassifiedCategoryPost.objects.filter(category=cid),many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)

@api_view(['GET'])
def classifiedCategoryPost(request, pk):
    serializer = ClassifiedPostSerializer(ClassifiedCategoryPost.objects.get(id=pk))
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
def gigDetails(request, gid):
    serializer = MicroGigPostDetailsSerializer(MicroGigPost.objects.get(id=gid))
    return Response(serializer.data, status=status.HTTP_200_OK)


# Micro Gig Post
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getUserMicroGigs(request,pk):
    serializer = MicroGigPostSerializer(MicroGigPost.objects.filter(user=pk), many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


# Micro Gig Post Update
@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_micro_gig_post(request, pk):
    try:
        micro_gig_post = get_object_or_404(MicroGigPost, id=pk)
        
        # Check if the user is the owner or a superuser
        if request.user == micro_gig_post.user or request.user.is_superuser:
            serializer = MicroGigPostSerializer(micro_gig_post, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data, status=status.HTTP_200_OK)
            else:
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        else:
            return Response({"error": "You are not authorized to update this post."}, status=status.HTTP_403_FORBIDDEN)
    
    except MicroGigPost.DoesNotExist:
        return Response({"error": "MicroGigPost not found."}, status=status.HTTP_404_NOT_FOUND)

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
  
class UserBalance(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = BalanceSerializer
    queryset = Balance.objects.all()
    lookup_field = 'email'

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


class TokenValidationView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def get(self, request):
        user = request.user

        # Generate tokens using Simple JWT
        refresh = RefreshToken.for_user(user)

        user_data = UserSerializer(user).data
        # Prepare the data to be returned
        data = {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': user_data
        }

        return Response(data)