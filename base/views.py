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
from django.db.models import Q
from uuid import UUID
from decimal import Decimal
from rest_framework.pagination import PageNumberPagination

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
    serializer = logoSerializer(Logo.objects.get())
    return Response(serializer.data)

@api_view(["GET"])
def getAdminNotice(request):
    serializer = AdminNoticeSerializer(AdminNotice.objects.all(),many=True)
    return Response(serializer.data)

@api_view(['POST'])
def register(request):
    data = request.data
    # del data['refer']
    # else refer = User.objects.filter(username=data['refer']).first() refer.refer_count ++
    serializer = UserSerializer(data=data)
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
    nids = data.pop('nid', [])
    for file in nids:
        try:
            nm = NID.objects.create(image=base64ToFile(file))
            user.nid.add(nm)
        except Exception as e:
            return Response(
                {'message': 'Failed to process NID', 'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

    if 'image' in data:
        try:
            data['image'] = base64ToFile(data['image'])
        except Exception as e:
            return Response(
                {'message': 'Failed to process image', 'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

    # Update other fields
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

class PersonRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer

    def get_object(self):
        email = self.kwargs.get('email')
        try:
            return User.objects.get(email=email)
        except User.DoesNotExist:
            raise NotFound({"error": f"No person found with email: {email}"})

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
    
class GetMicroGigs(generics.ListCreateAPIView):
    queryset = MicroGigPost.objects.filter().order_by('-created_at')
    serializer_class = MicroGigPostSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)



@api_view(['POST'])
@permission_classes([IsAuthenticated])
def post_micro_gigs(request):
    data = request.data # Make a mutable copy of the data
    user=request.user
    data['user'] = user.id  # Associate the authenticated user
    serializer = MicroGigPostSerializer(data=data)
    if serializer.is_valid():
        if user.balance < data['total_cost']:
            raise ValueError("Insufficient balance")
        user.balance -= data['total_cost']
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

class ClassifiedCategoryPostFilterView(APIView):
    def get(self, request):
        country = request.GET.get('country')
        state = request.GET.get('state')
        city = request.GET.get('city')
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
        

        posts = ClassifiedCategoryPost.objects.filter(filters)

        print(posts)
        serializer = ClassifiedPostSerializer(posts, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

@api_view(['GET'])
def classifiedCategoryPosts(request, cid):
    serializer = ClassifiedPostSerializer(ClassifiedCategoryPost.objects.filter(category=cid).order_by('-created_at'),many=True)
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
def getUserMicroGigs(request,pk):
    serializer = MicroGigPostSerializer(MicroGigPost.objects.filter(user=pk), many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)
# Micro Gig Post
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_micro_gig_post(request,pk):
    serializer = MicroGigPostSerializer(MicroGigPost.objects.get(id=pk))
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


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def postMicroGigPostTask(request):
    # Add the user ID (pk) to the incoming data
    data = request.data.copy()
    data['user'] = request.user.id
    
    # Serialize and validate the data
    serializer = MicroGigPostTaskSerializer(data=data)
    
    if serializer.is_valid():
        new_micro_gig_post_task = serializer.save(user=request.user)  # Save the new MicroGigPostTask instance
        print(f"New MicroGigPostTask instance: {new_micro_gig_post_task}")  # Debugging: check the saved instance
        
        # Handle medias safely
        for file in data.get('medias', []):
            nm = MicroGigPostMedia.objects.create(image=base64ToFile(file))
            new_micro_gig_post_task.medias.add(nm)
        
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    # Print errors if validation fails
    print(serializer.errors)
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
    tasks = micro_gig_post.microgigposttask_set.all().order_by('-created_at')

    # Serialize the tasks
    serializer = GetMicroGigPostTaskSerializer(tasks, many=True)

    return Response(serializer.data, status=status.HTTP_200_OK)

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_microgigpost_tasks(request, gig_id):
    """
    Update tasks associated with a specific MicroGigPost.
    """
    try:
        # Retrieve the MicroGigPost instance
        micro_gig_post = MicroGigPost.objects.get(id=gig_id)
    except MicroGigPost.DoesNotExist:
        return Response(
            {"error": "MicroGigPost not found"},
            status=status.HTTP_404_NOT_FOUND
        )

    # Retrieve the tasks related to this MicroGigPost
    tasks = micro_gig_post.microgigposttask_set.all()

    # Validate and update each task
    data = request.data.get('tasks', [])
    if not isinstance(data, list):
        return Response(
            {"error": "Expected a list of tasks in 'tasks' field."},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Create a list to track updated tasks
    updated_tasks = []

    for task_data in data:
        task_id = task_data.get('id')
        if not task_id:
            return Response(
                {"error": "Task 'id' is required for updates."},
                status=status.HTTP_400_BAD_REQUEST
            )
        try:
            # Get the task instance
            task = tasks.get(id=task_id)
        except MicroGigPostTask.DoesNotExist:
            return Response(
                {"error": f"Task with id {task_id} not found."},
                status=status.HTTP_404_NOT_FOUND
            )

        # Serialize the task data and validate
        serializer = GetMicroGigPostTaskSerializer(task, data=task_data, partial=True)
        if serializer.is_valid():
            # Save the updated task
            serializer.save()
            updated_tasks.append(serializer.data)
        else:
            return Response(
                {"error": f"Invalid data for task with id {task_id}.", "details": serializer.errors},
                status=status.HTTP_400_BAD_REQUEST
            )

    return Response({"updated_tasks": updated_tasks}, status=status.HTTP_200_OK)



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
    
    # Check if Balance with the given merchant_invoice_no exists
    try:
        does_exist = Balance.objects.get(merchant_invoice_no=data['merchant_invoice_no'])
        return Response(
            {"error": "Balance with this merchant invoice number already exists."},
            status=status.HTTP_400_BAD_REQUEST
        )
    except Balance.DoesNotExist:
        # If the Balance doesn't exist, proceed with the operations
        serializer = BalanceSerializer(data=data)
        
        if serializer.is_valid():
            # Save the new Balance instance
            serializer.save(user=request.user)
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

        user_data = UserSerializer(user).data
        # Prepare the data to be returned
        data = {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': user_data
        }

        return Response(data)
    



# for frontend

def index(request, **args):
    return render(request, 'index.html')