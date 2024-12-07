from django.shortcuts import render
from rest_framework import status
from rest_framework.response import Response
from rest_framework import generics
from .models import ClassifiedCategory,User,MicroGigPost,Balance
from .serializers import ClassifiedServicesSerializer,CustomTokenObtainPairSerializer,UserSerializer,MicroGigPostSerializer,MicroGigPostDetailsSerializer,BalanceSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import AllowAny
from rest_framework.decorators import api_view
from rest_framework.exceptions import NotFound

# Create your views here.


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

permission_classes = [IsAuthenticated]
@api_view(['PUT'])
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
        # data = {
        #     "message": "Product details fetched successfully",
        #     "data": serializer.data,
        # }
        return Response(serializer.data, status=status.HTTP_200_OK)

@api_view(('GET',))
def gigDetails(request, gid):
    serializer = MicroGigPostDetailsSerializer(MicroGigPost.objects.get(id=gid))
    return Response(serializer.data, status=status.HTTP_200_OK)
  
class UserBalance(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = BalanceSerializer
    queryset = Balance.objects.all()
    lookup_field = 'email'
    
    
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