import base64
import json
import random
import re
import uuid
from decimal import Decimal
from random import shuffle

import requests
from django.conf import settings
from django.contrib.auth import authenticate
from django.contrib.auth.hashers import check_password
from django.core.files.base import ContentFile
from django.core.mail import send_mail
from django.db.models import Q
from django.http import JsonResponse
from django.shortcuts import get_object_or_404, render
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.exceptions import NotFound
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import *
from .pagination import *
from .police_stations import CITY_AREAS
from .serializers import *

# Create your views here.


@api_view(["POST"])
def login_as_view(request):
    username = request.data.get("username")
    password = request.data.get("password")
    # Username of the user to log in as
    login_as = request.data.get("login_as")

    user = authenticate(username=username, password=password)

    if user is not None and user.is_staff:  # check if user is admin
        try:
            login_as_user = User.objects.get(
                username=login_as
            )  # Get the user to log in as
            refresh = RefreshToken.for_user(login_as_user)
            return Response(
                {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                }
            )
        except User.DoesNotExist:
            return Response({"error": "Target user not found"}, status=404)
    else:
        return Response({"error": "Invalid admin credentials"}, status=400)


# move this function to util later
def base64ToFile(base64_data):
    # Remove the prefix if it exists (e.g., "data:image/png;base64,")
    if base64_data.startswith("data:image"):
        base64_data = base64_data.split("base64,")[1]

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
def get_eshop_logo(request):
    e_shop_logo = get_object_or_404(EshopLogo)
    serializer = EshopLogoSerializer(e_shop_logo)
    return Response(serializer.data)


@api_view(["GET"])
def getAuthenticationBanner(request):
    banner = get_object_or_404(AuthenticationBanner)
    serializer = AuthenticationBannerSerializer(banner)
    return Response(serializer.data)


@api_view(["GET"])
def getAdminNotice(request):
    # Get query parameters
    notification_type = request.GET.get("type", None)
    user_id = request.user.id if request.user.is_authenticated else None

    # Base queryset - include global notices and user-specific notices
    queryset = AdminNotice.objects.all()

    if user_id:
        # Include global notices (user=None) and user-specific notices
        queryset = queryset.filter(models.Q(user=None) | models.Q(user_id=user_id))
    else:
        # For anonymous users, only show global notices
        queryset = queryset.filter(user=None)

    # Filter by notification type if specified
    if notification_type and notification_type != "all":
        queryset = queryset.filter(notification_type=notification_type)

    # Order by creation date
    queryset = queryset.order_by("-created_at")

    serializer = AdminNoticeSerializer(queryset, many=True)
    return Response(serializer.data)


@api_view(["POST"])
def register(request):
    data = request.data

    # Check if user with phone or email already exists
    if User.objects.filter(phone=data.get("phone")).exists():
        return Response(
            {"error": "User with this phone number already exists"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if User.objects.filter(email=data.get("email")).exists():
        return Response(
            {"error": "User with this email already exists"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Handle referral
    ref_by = None
    if "refer" in data:
        ref_by = User.objects.filter(referral_code=data["refer"]).first()
        del data["refer"]
    if "image" in data:
        try:
            data["image"] = base64ToFile(data["image"])
        except Exception as e:
            return Response(
                {"message": "Failed to process image", "error": str(e)},
                status=status.HTTP_400_BAD_REQUEST,
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
            {"message": "Person registered successfully", "data": serializer.data},
            status=status.HTTP_201_CREATED,
        )
    print(serializer.errors)
    return Response(
        {"message": "Validation failed", "errors": serializer.errors},
        status=status.HTTP_400_BAD_REQUEST,
    )


@api_view(["GET"])
def get_top_contributors(request):
    top_contributors = User.objects.filter(is_topcontributor=True)
    serializer = UserSerializer(top_contributors, many=True)
    return Response(serializer.data)


@api_view(["PUT"])
@permission_classes([IsAuthenticated])
def update_user(request, email):
    data = request.data
    print(data)
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({"message": "User not found"}, status=status.HTTP_404_NOT_FOUND)
    # Remove email from data if it's unchanged
    if "email" in data and data["email"] == user.email:
        data.pop("email")

    if "image" in data:
        try:
            data["image"] = base64ToFile(data["image"])
        except Exception as e:
            return Response(
                {"message": "Failed to process image", "error": str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )
    if "store_banner" in data:
        try:
            data["store_banner"] = base64ToFile(data["store_banner"])
        except Exception as e:
            return Response(
                {"message": "Failed to process store banner", "error": str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )
    data["id"] = user.id
    serializer = UserSerializer(user, data=data, partial=True)

    if serializer.is_valid():
        try:
            user.save()  # Save any direct changes to the user instance
            serializer.save()  # Save changes from the serializer
            return Response(
                {"message": "User updated successfully", "data": serializer.data},
                status=status.HTTP_200_OK,
            )
        except Exception as e:
            return Response(
                {"message": "Failed to save user", "error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    print(serializer.errors)
    # Return validation errors if serializer is not valid
    return Response(
        {"message": "Validation failed", "errors": serializer.errors},
        status=status.HTTP_400_BAD_REQUEST,
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


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_nid(request):
    try:
        nid = NID.objects.get(user=request.user)

        serializer = NIDSerializer(nid)
        print(nid)
        return Response(
            {"message": "NID details retrieved successfully", "data": serializer.data},
            status=status.HTTP_200_OK,
        )
    except NID.DoesNotExist:
        return Response(
            {"message": "NID not found for the user"}, status=status.HTTP_404_NOT_FOUND
        )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def add_nid(request):
    data = request.data
    data["user"] = request.user.id
    fields_to_process = ["front", "back", "selfie", "other_document"]
    for field in fields_to_process:
        if field in data and data[field] not in [None, "", "null"]:
            try:
                data[field] = base64ToFile(data[field])
            except Exception as e:
                return Response(
                    {"message": f"Failed to process {field} image", "error": str(e)},
                    status=status.HTTP_400_BAD_REQUEST,
                )
    serializer = NIDSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return Response(
            {"message": "NID Added successfully", "data": serializer.data},
            status=status.HTTP_200_OK,
        )
    print(serializer.errors)
    return Response(
        {"message": "Failed to add NID", "errors": serializer.errors},
        status=status.HTTP_400_BAD_REQUEST,
    )


@api_view(["PUT"])
@permission_classes([IsAuthenticated])
def update_nid(request):
    try:
        nid = NID.objects.get(user=request.user)
    except NID.DoesNotExist:
        return Response(
            {"message": "NID not found for the user"}, status=status.HTTP_404_NOT_FOUND
        )

    data = request.data
    if "front" in data:
        try:
            data["front"] = base64ToFile(data["front"])
        except Exception as e:
            return Response(
                {"message": "Failed to process front image", "error": str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )
    if "back" in data:
        try:
            data["back"] = base64ToFile(data["back"])
        except Exception as e:
            return Response(
                {"message": "Failed to process back image", "error": str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )

    serializer = NIDSerializer(nid, data=data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(
            {"message": "NID updated successfully", "data": serializer.data},
            status=status.HTTP_200_OK,
        )
    return Response(
        {"message": "Failed to update NID", "errors": serializer.errors},
        status=status.HTTP_400_BAD_REQUEST,
    )


class PersonRetrieveView(generics.RetrieveAPIView):
    queryset = User.objects.all()
    # permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer
    lookup_field = "id"

    def get_object(self):
        queryset = self.filter_queryset(self.get_queryset())

        # Get the lookup value from URL
        lookup_url_kwarg = self.lookup_url_kwarg or self.lookup_field
        assert lookup_url_kwarg in self.kwargs, (
            f"Expected view {self.__class__.__name__} to be called with a URL keyword argument "
            f'named "{lookup_url_kwarg}". Fix your URL conf, or set the `.lookup_field` '
            f"attribute on the view correctly."
        )

        lookup_value = self.kwargs[lookup_url_kwarg]

        # Determine if it's an email, phone or ID based on the value format
        if "@" in str(lookup_value):
            # Email lookup
            filter_kwargs = {"email": lookup_value}
            lookup_type = "email"
        elif str(lookup_value).isdigit() and len(str(lookup_value)) >= 10:
            # Phone lookup - assuming phone numbers are at least 10 digits
            filter_kwargs = {"phone": lookup_value}
            lookup_type = "phone"
        else:
            # ID lookup
            filter_kwargs = {"id": lookup_value}
            lookup_type = "ID"

        # Get the object
        try:
            obj = queryset.get(**filter_kwargs)
        except User.DoesNotExist:
            raise NotFound(
                {"error": f"No person found with {lookup_type}: {lookup_value}"}
            )

        # Check object permissions
        self.check_object_permissions(self.request, obj)
        return obj


class PersonRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer

    def get_object(self):
        email = self.kwargs.get("email")
        try:
            return User.objects.get(email=email)
        except User.DoesNotExist:
            raise NotFound({"error": f"No person found with email: {email}"})


class PersonImageDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, email):
        try:
            user = User.objects.get(email=email)

            if user.image:
                user.image.delete(save=False)
                user.image = None
                user.save()
                return Response(
                    {"detail": "User image deleted successfully."},
                    status=status.HTTP_200_OK,
                )
            else:
                return Response(
                    {"detail": "User has no image to delete."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        except User.DoesNotExist:
            raise NotFound({"error": f"No person found with email: {email}"})


@api_view(["GET"])
def get_user_with_identifier(request, identifier):
    print(identifier)
    try:
        user = User.objects.get(Q(email=identifier) | Q(phone=identifier))
        return Response(
            {
                "id": user.id,
                "email": user.email,
                "phone": user.phone,
                "name": user.name,  # Include additional fields as needed
            }
        )
    except User.DoesNotExist:
        raise NotFound({"error": f"No person found with email or phone: {identifier}"})


class ClassifiedCategoryPagination(PageNumberPagination):
    page_size = 12
    # def get_page_size(self, request):
    #     if request.query_params.get(self.page_query_param) in [None, '', '1']:
    #         return 14
    #     return self.page_size


class GetClassifiedCategories(generics.ListCreateAPIView):
    queryset = ClassifiedCategory.objects.all().order_by("-is_featured", "-updated_at")
    serializer_class = ClassifiedServicesSerializer
    permission_classes = [AllowAny]
    pagination_class = ClassifiedCategoryPagination

    def get_queryset(self):
        """
        Filter the queryset by title or search keywords.
        """
        queryset = ClassifiedCategory.objects.all().order_by(
            "-is_featured", "-updated_at"
        )
        search_term = self.request.query_params.get("title", None)

        if search_term:
            # Create a Q object for OR conditions in the filter
            from django.db.models import Q

            # Search in title
            title_query = Q(title__icontains=search_term)

            # Search in search_keywords (looking for individual keywords)
            keyword_query = Q(search_keywords__icontains=search_term)

            # Combine queries with OR
            queryset = queryset.filter(title_query | keyword_query).distinct()

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


class ClassifiedCategoryDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update or delete a specific classified category"""

    queryset = ClassifiedCategory.objects.all()
    serializer_class = ClassifiedServicesSerializer
    # For reading; you might want IsAdminUser for writing
    permission_classes = [AllowAny]
    lookup_field = "slug"


class GetClassifiedCategoriesAll(generics.ListCreateAPIView):
    queryset = ClassifiedCategory.objects.all().order_by("title")
    serializer_class = ClassifiedServicesSerializer
    permission_classes = [AllowAny]


class GetMicroGigs(generics.ListCreateAPIView):
    serializer_class = MicroGigPostSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = MicroGigPost.objects.exclude(
            gig_status__in=["pending", "rejected", "completed"]
        )

        # Get category from query params
        category = self.request.query_params.get("category", None)
        show_submitted = self.request.query_params.get("show_submitted", None)
        show_all = self.request.query_params.get("show_all", None)
        user = self.request.user

        if category:
            queryset = queryset.filter(category=category)

        if user.is_authenticated and show_all != "true":
            if show_submitted == "true":
                # Show only gigs where user has submitted tasks
                queryset = queryset.filter(microgigposttask__user=user).distinct()
            elif show_submitted == "false":
                # Show only gigs where user hasn't submitted tasks
                queryset = queryset.exclude(microgigposttask__user=user)
            else:
                # Default: Show only gigs where user hasn't submitted tasks
                queryset = queryset.exclude(microgigposttask__user=user)

        return queryset.order_by("-created_at")

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


# Micro Gig Post
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def post_micro_gigs(request):
    data = request.data  # Make a mutable copy of the data
    user = request.user
    data["user"] = user.id  # Associate the authenticated user
    serializer = MicroGigPostSerializer(data=data)
    if serializer.is_valid():
        if user.balance < data["total_cost"]:
            # raise ValueError("Insufficient balance")
            return Response(
                {"message": "Insufficient balance", "errors": "Insufficient balance"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        user.balance -= Decimal(data["total_cost"])
        user.save()
        new_micro_gig_post = serializer.save(user=user)
        for file in data["medias"]:
            nm = MicroGigPostMedia.objects.create(image=base64ToFile(file))
            new_micro_gig_post.medias.add(nm)

        # Create notification for successful gig posting
        try:
            create_gig_posted_notification(
                user=user,
                gig_title=new_micro_gig_post.title,
                gig_id=str(new_micro_gig_post.id),
            )
        except Exception as e:
            print(f"Error creating gig posted notification: {str(e)}")

        return Response(
            {"message": "Person Updated successfully", "data": serializer.data},
            status=status.HTTP_201_CREATED,
        )
    if serializer.errors:
        print(serializer.errors)
    return Response(
        {"message": "Validation failed", "errors": serializer.errors},
        status=status.HTTP_400_BAD_REQUEST,
    )


# Micro Gig Put Update


@api_view(["PUT"])
@permission_classes([IsAuthenticated])
def update_micro_gig_post(request, pk):
    try:
        micro_gig_post = get_object_or_404(MicroGigPost, id=pk)

        # Check if the user is the owner or a superuser
        if request.user == micro_gig_post.user or request.user.is_superuser:
            additional_cost = Decimal(request.data.get("additional_cost", 0))

            # Ensure the user has enough balance for the additional cost
            if request.user.balance < additional_cost:
                return Response(
                    {
                        "message": "Insufficient balance",
                        "errors": "Insufficient balance",
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # Deduct additional cost from user balance
            request.user.balance -= additional_cost
            request.user.save()
            print(micro_gig_post.total_cost + additional_cost)
            # Adjust balance and quantity in micro_gig_post
            micro_gig_post.total_cost = micro_gig_post.total_cost + additional_cost
            micro_gig_post.balance += Decimal(request.data.get("balance", 0))
            micro_gig_post.required_quantity += int(
                request.data.get("required_quantity", 0)
            )

            # Update the MicroGigPost using serializer
            serializer = MicroGigPostSerializer(
                micro_gig_post, data=request.data, partial=True
            )
            if serializer.is_valid():
                try:
                    serializer.save()
                    return Response(serializer.data, status=status.HTTP_200_OK)
                except ValidationError as e:
                    # Return the validation error message from the model
                    return Response(
                        {"error": str(e)}, status=status.HTTP_400_BAD_REQUEST
                    )
            else:
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        else:
            return Response(
                {"error": "You are not authorized to update this post."},
                status=status.HTTP_403_FORBIDDEN,
            )

    except ValidationError as e:
        # Handle any validation errors that might occur outside the serializer.save()
        return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
    except MicroGigPost.DoesNotExist:
        return Response(
            {"error": "MicroGigPost not found."}, status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        # Log the error for debugging
        print(f"Unexpected error in update_micro_gig_post: {str(e)}")
        return Response(
            {"error": "Can't stop the gig. You have pending tasks"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def post_classified_service(request):
    data = request.data.copy()  # Make a mutable copy of the data
    data["user"] = request.user.id  # Associate the authenticated user
    category_id = data.get("category")
    if not ClassifiedCategory.objects.filter(id=category_id).exists():
        raise ValidationError({"category": "The specified category does not exist."})
    serializer = ClassifiedPostSerializer(data=data)

    if serializer.is_valid():
        new_classified_service_post = serializer.save(user=request.user)
        for file in data.get("medias", []):
            nm = ClassifiedCategoryPostMedia.objects.create(image=base64ToFile(file))
            new_classified_service_post.medias.add(nm)

        return Response(
            {"message": "Person Updated successfully", "data": serializer.data},
            status=status.HTTP_201_CREATED,
        )
    print(serializer.errors)
    return Response(
        {"message": "Validation failed", "errors": serializer.errors},
        status=status.HTTP_400_BAD_REQUEST,
    )


class ClassifiedPostPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100


class GetClassifiedPosts(generics.ListAPIView):
    serializer_class = ClassifiedPostSerializer
    pagination_class = ClassifiedPostPagination
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = (
            ClassifiedCategoryPost.objects.filter(service_status="approved")
            .select_related("category")
            .defer(
                "user"  # Tell Django not to load the user field
            )
            .order_by("-created_at")
        )

        title = self.request.query_params.get("title", None)

        if title:
            queryset = queryset.filter(
                Q(title__icontains=title) | Q(instructions__icontains=title)
            )

        return queryset


class ClassifiedCategoryPostFilterView(generics.ListAPIView):
    serializer_class = ClassifiedPostSerializer
    pagination_class = ClassifiedPostPagination
    permission_classes = [AllowAny]

    def get_queryset(self):
        country = self.request.GET.get("country")
        state = self.request.GET.get("state")
        city = self.request.GET.get("city")
        upazila = self.request.GET.get("upazila")
        category = self.request.GET.get("category")
        title = self.request.GET.get("title")

        # Filter based on the query parameters
        filters = Q()
        if category and category != "undefined" and category.strip():
            try:
                # Validate that category is a valid UUID before using it
                uuid.UUID(str(category))
                filters &= Q(category__id=category)
            except (ValueError, AttributeError):
                # Invalid UUID format, skip category filter
                pass
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

        posts = ClassifiedCategoryPost.objects.filter(filters).order_by("-created_at")
        return posts


@api_view(["GET"])
def classifiedCategoryPosts(request, cid):
    posts = list(ClassifiedCategoryPost.objects.filter(category=cid))
    # for random category posts
    shuffle(posts)
    serializer = ClassifiedPostSerializer(posts, many=True)

    # serializer = ClassifiedPostSerializer(ClassifiedCategoryPost.objects.filter(category=cid).order_by('-created_at'),many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(["GET"])
def UserClassifiedCategoryPosts(request):
    # Get the logged-in user
    user = request.user

    # Filter posts by category and user
    posts = ClassifiedCategoryPost.objects.filter(user=user).order_by("title")

    # Serialize the filtered posts
    serializer = ClassifiedPostSerializer(posts, many=True)

    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(["GET"])
def classifiedCategoryPost(request, slug):
    try:
        post = ClassifiedCategoryPost.objects.get(slug=slug)
        serializer = ClassifiedPostSerializer(post)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except ClassifiedCategoryPost.DoesNotExist:
        # Fallback to ID in case slug is not found (for backwards compatibility)
        try:
            post = ClassifiedCategoryPost.objects.get(id=slug)
            serializer = ClassifiedPostSerializer(post)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except ClassifiedCategoryPost.DoesNotExist:
            return Response(
                {"error": "Post not found"}, status=status.HTTP_404_NOT_FOUND
            )


@api_view(["PUT"])
@permission_classes([IsAuthenticated])
def update_classified_post(request, pk):
    print(request.data, "data")
    try:
        classified_post = get_object_or_404(ClassifiedCategoryPost, id=pk)

        # Check if the user is the owner or a superuser
        if request.user == classified_post.user or request.user.is_superuser:
            # Get a mutable copy of request data
            data = request.data.copy()

            # Handle media files separately
            medias = data.pop("medias", None)

            # Update the post details
            serializer = ClassifiedPostSerializer(
                classified_post, data=data, partial=True
            )
            if serializer.is_valid():
                updated_post = serializer.save()

                # Process media files if present
                if medias:
                    # Option 1: Clear existing media and add new ones
                    if data.get("replace_all_media", False):
                        # Remove existing media
                        updated_post.medias.clear()

                    # Add new media files
                    for file in medias:
                        # Check if it's base64
                        if isinstance(file, str) and file.startswith("data:"):
                            nm = ClassifiedCategoryPostMedia.objects.create(
                                image=base64ToFile(file)
                            )
                            updated_post.medias.add(nm)

                # Get the updated data with media included
                updated_serializer = ClassifiedPostSerializer(updated_post)
                return Response(updated_serializer.data, status=status.HTTP_200_OK)
            else:
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        else:
            return Response(
                {"error": "You are not authorized to update this post."},
                status=status.HTTP_403_FORBIDDEN,
            )

    except ClassifiedCategoryPost.DoesNotExist:
        return Response(
            {"error": "ClassifiedCategoryPost not found."},
            status=status.HTTP_404_NOT_FOUND,
        )
    except Exception as e:
        print(f"Error updating classified post: {str(e)}")
        return Response(
            {"error": f"An error occurred: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


# Classified Post Delete


@api_view(["DELETE"])
@permission_classes([IsAuthenticated])
def delete_classified_post(request, pk):
    try:
        classified_post = get_object_or_404(ClassifiedCategoryPost, id=pk)

        # Check if the user is the owner or a superuser
        if request.user == classified_post.user or request.user.is_superuser:
            classified_post.delete()
            return Response(
                {"message": "ClassifiedCategoryPost deleted successfully."},
                status=status.HTTP_200_OK,
            )
        else:
            return Response(
                {"error": "You are not authorized to delete this post."},
                status=status.HTTP_403_FORBIDDEN,
            )

    except ClassifiedCategoryPost.DoesNotExist:
        return Response(
            {"error": "ClassifiedCategoryPost not found."},
            status=status.HTTP_404_NOT_FOUND,
        )


@api_view(["GET"])
def gigDetails(request, gid):
    serializer = MicroGigPostDetailsSerializer(MicroGigPost.objects.get(slug=gid))
    return Response(serializer.data, status=status.HTTP_200_OK)


# All Micro Gig Post
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getUserMicroGigs(request, pk):
    # Order completed gigs to appear at the bottom
    queryset = MicroGigPost.objects.filter(user=pk).order_by(
        # This puts non-completed gigs first, then completed ones
        models.Case(models.When(gig_status="completed", then=1), default=0),
        "-created_at",  # Within each group, show newest first
    )

    serializer = MicroGigPostSerializer(queryset, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


# Micro Gig Post


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_micro_gig_post(request, pk):
    serializer = MicroGigPostSerializer(MicroGigPost.objects.get(id=pk))
    return Response(serializer.data, status=status.HTTP_200_OK)


# Micro Gig Post Delete
@api_view(["DELETE"])
@permission_classes([IsAuthenticated])
def delete_micro_gig_post(request, pk):
    try:
        micro_gig_post = get_object_or_404(MicroGigPost, id=pk)

        # Check if the user is the owner or a superuser
        if request.user == micro_gig_post.user or request.user.is_superuser:
            micro_gig_post.delete()
            return Response(
                {"message": "MicroGigPost deleted successfully."},
                status=status.HTTP_200_OK,
            )
        else:
            return Response(
                {"error": "You are not authorized to delete this post."},
                status=status.HTTP_403_FORBIDDEN,
            )

    except MicroGigPost.DoesNotExist:
        return Response(
            {"error": "MicroGigPost not found."}, status=status.HTTP_404_NOT_FOUND
        )


# Micro Gig Post Task


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMicroGigPostTasks(request, email):
    serializer = MicroGigPostTaskSerializer(
        MicroGigPostTask.objects.filter(user=email), many=True
    )
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def postMicroGigPostTask(request):
    data = request.data.copy()
    data["user"] = request.user.id
    gig_id = data.get("gig")

    # Check if user has already submitted a task for this gig
    existing_task = MicroGigPostTask.objects.filter(
        user=request.user, gig_id=gig_id
    ).exists()

    if existing_task:
        return Response(
            {"error": "You have already submitted a task for this gig"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # If no existing task, proceed with creation
    serializer = MicroGigPostTaskSerializer(data=data)
    if serializer.is_valid():
        new_micro_gig_post_task = serializer.save(user=request.user)

        # Handle medias
        for file in data.get("medias", []):
            nm = MicroGigPostMedia.objects.create(image=base64ToFile(file))
            new_micro_gig_post_task.medias.add(nm)

        return Response(serializer.data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getPendingTasks(request):
    serializer = GetMicroGigPostTaskSerializer(
        MicroGigPostTask.objects.filter(user=request.user).order_by("-created_at"),
        many=True,
    )
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(["GET"])
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
            {"error": "MicroGigPost not found"}, status=status.HTTP_404_NOT_FOUND
        )

    # Get all tasks associated with this MicroGigPost
    tasks = micro_gig_post.microgigposttask_set.all().order_by(
        models.Case(
            # Order: pending (not approved and not rejected) first, then approved, then rejected
            models.When(approved=True, then=1),
            models.When(rejected=True, then=2),
            default=0,  # Pending tasks
        ),
        "-created_at",  # Then by creation date (newest first)
    )

    # Serialize the tasks
    serializer = GetMicroGigPostTaskSerializer(tasks, many=True)

    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(["PUT"])
@permission_classes([IsAuthenticated])
def update_microgigpost_tasks(request, gig_id):
    try:
        micro_gig_post = MicroGigPost.objects.get(id=gig_id)

        if request.user != micro_gig_post.user and not request.user.is_staff:
            return Response(
                {"error": "You don't have permission to update tasks for this gig"},
                status=status.HTTP_403_FORBIDDEN,
            )

        tasks_data = request.data.get("tasks", [])
        if not tasks_data:
            return Response(
                {"error": "No tasks provided"}, status=status.HTTP_400_BAD_REQUEST
            )

        updated_tasks = []
        for task_data in tasks_data:
            task_id = task_data.get("id")
            try:
                task = MicroGigPostTask.objects.get(id=task_id, gig=micro_gig_post)

                # Update task status
                if task_data.get("rejected"):
                    task.rejected = True
                    task.reason = task_data.get("reason", "")  # Set rejection reason
                    # task.completed = True  # Mark as completed when rejected
                elif task_data.get("approved"):
                    task.approved = True
                    # task.completed = True  # Mark as completed when approved

                task.save()
                serializer = GetMicroGigPostTaskSerializer(task)
                updated_tasks.append(serializer.data)

            except MicroGigPostTask.DoesNotExist:
                return Response(
                    {"error": f"Task {task_id} not found"},
                    status=status.HTTP_404_NOT_FOUND,
                )

        return Response(
            {"message": "Tasks updated successfully", "updated_tasks": updated_tasks},
            status=status.HTTP_200_OK,
        )

    except MicroGigPost.DoesNotExist:
        return Response(
            {"error": "MicroGigPost not found"}, status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        print(f"Error updating tasks: {str(e)}")  # Add logging
        return Response(
            {"error": "Server error occurred"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
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
        return Balance.objects.filter(user=self.request.user).order_by("-updated_at")


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def postBalance(request):
    # Add the user ID (pk) to the incoming data
    data = request.data.copy()
    data["user"] = request.user.id
    print(data)
    to_user = None
    data["payable_amount"] = Decimal(data["payable_amount"]).quantize(
        # Check minimum deposit amount for deposit transactions
        Decimal("0.01")
    )
    if data.get("transaction_type", "").lower() == "deposit":
        if data["payable_amount"] < Decimal("100.00"):
            return Response(
                {"error": "Minimum deposit amount is ৳100.00"},
                status=status.HTTP_400_BAD_REQUEST,
            )
    # Check minimum withdrawal amount for withdrawal transactions
    if data.get("transaction_type", "").lower() == "withdraw":
        if data["payable_amount"] < Decimal("200.00"):
            return Response(
                {"error": "Minimum withdrawal amount is ৳200.00"},
                status=status.HTTP_400_BAD_REQUEST,
            )

    # Check minimum transfer amount for transfer transactions
    if data.get("transaction_type", "").lower() == "transfer":
        if data["payable_amount"] < Decimal("50.00"):
            return Response(
                {"error": "Minimum transfer amount is ৳50.00"},
                status=status.HTTP_400_BAD_REQUEST,
            )

    # Check if 'merchant_invoice_no' exists in the data
    if "merchant_invoice_no" in data:
        # Check if Balance with the given merchant_invoice_no exists
        if Balance.objects.filter(
            merchant_invoice_no=data["merchant_invoice_no"]
        ).exists():
            return Response(
                {"error": "Balance with this merchant invoice number already exists."},
                status=status.HTTP_400_BAD_REQUEST,
            )
    # else:
    #     # Return an error if 'merchant_invoice_no' is missing
    #     return Response(
    #         {"error": "The 'merchant_invoice_no' field is required."},
    #         status=status.HTTP_400_BAD_REQUEST
    #     )      # Proceed with the operations if 'merchant_invoice_no' is valid
    if "contact" in data and data["contact"]:
        to_user = User.objects.get(Q(email=data["contact"]) | Q(phone=data["contact"]))
        del data["contact"]

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
        return AdminNotice.objects.all().order_by("-created_at")


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

    def dispatch(self, *args, **kwargs):
        return super().dispatch(*args, **kwargs)

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
            return Response(serializer.validated_data, status=status.HTTP_200_OK)
        except Exception:
            # Extract error details
            error_message = serializer.errors.get(
                "non_field_errors", ["Invalid credentials"]
            )[0]
            return Response(
                {"error": error_message}, status=status.HTTP_401_UNAUTHORIZED
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
            "refresh": str(refresh),
            "access": str(refresh.access_token),
            "user": user_data,
        }

        return Response(data)


@api_view(["GET"])
def get_faq(request):
    faqs = Faq.objects.all()
    serializer = FaqSerializer(faqs, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


# @api_view(['GET'])
# def get_police_stations(request, district_id):
#     police_stations = PoliceStation.objects.filter(district=district_id)
#     serializer = PoliceStationSerializer(police_stations, many=True)
#     return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(["GET"])
def police_station(request):
    # Get city from query param, capitalize to match dictionary keys
    city = request.GET.get("city", "").strip().capitalize()
    if not city:
        return Response({"error": "City name is required"}, status=400)

    areas = CITY_AREAS.get(city, [])  # Fetch areas for the specified city
    if not areas:
        return Response({"error": f"No areas found for city: {city}"}, status=404)

    return Response(data=areas)


@permission_classes([IsAuthenticated])
@api_view(["POST", "GET"])
def smsSend(request):
    phone = request.GET.get("phone")
    message = "Welcome to AdsyClub.com! You can now connect people enjoy services around you and earn money by completing tasks. Thank you!"
    url = "http://api.smsinbd.com/sms-api/sendsms"
    payload = {
        "api_token": settings.API_SMS,
        "senderid": "8809617614969",
        "contact_number": phone,
        "message": message,
    }

    try:
        # Add timeout to prevent ECONNABORTED errors
        response = requests.get(url, params=payload, timeout=10)
        print(response.text)
        return Response(response.text, status=status.HTTP_200_OK)
    except requests.exceptions.Timeout:
        print("SMS API request timed out")
        return Response(
            {"error": "SMS service timeout"}, status=status.HTTP_408_REQUEST_TIMEOUT
        )
    except requests.exceptions.ConnectionError:
        print("SMS API connection error")
        return Response(
            {"error": "SMS service unavailable"},
            status=status.HTTP_503_SERVICE_UNAVAILABLE,
        )
    except requests.exceptions.RequestException as e:
        print(f"SMS API request failed: {str(e)}")
        return Response(
            {"error": "SMS service error"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["POST"])
def sendOTP(request):
    phone = request.data.get("phone")
    email = request.data.get("email")
    method = request.data.get("method", "phone")

    # Validate input based on method
    if method == "phone":
        if not phone:
            return Response(
                {"error": "Phone number is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Clean and validate phone format
        phone = phone.strip()
        phone_pattern = r"^(?:\+?88)?01[3-9]\d{8}$"
        if not re.match(phone_pattern, phone):
            return Response(
                {
                    "error": "Please enter a valid Bangladeshi phone number (e.g., 01XXXXXXXXX)"
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Normalize phone number (remove +88 if present, ensure it starts with 01)
        if phone.startswith("+88"):
            phone = phone[3:]
        elif phone.startswith("88"):
            phone = phone[2:]

        # Check if user exists with this phone number
        try:
            user = User.objects.get(phone=phone)
        except User.DoesNotExist:
            return Response(
                {
                    "error": "No account found with this phone number. Please check the number and try again."
                },
                status=status.HTTP_404_NOT_FOUND,
            )

    elif method == "email":
        # Email reset temporarily disabled until SMTP is configured
        return Response(
            {
                "error": "Email reset is temporarily unavailable. Please use phone number."
            },
            status=status.HTTP_503_SERVICE_UNAVAILABLE,
        )

    else:
        return Response(
            {"error": "Invalid method. Use phone or email"},
            status=status.HTTP_400_BAD_REQUEST,
        )
    # Generate secure 6-digit OTP
    otp = str(random.randint(100000, 999999))

    # Save OTP to user and clear any existing attempt counters
    user.otp = otp
    user.save()

    # Clear any existing OTP attempt counters for this contact
    from django.core.cache import cache

    if method == "phone":
        cache.delete(f"otp_attempts_{phone}")
    elif method == "email":
        cache.delete(f"otp_attempts_{email}")

    if method == "phone":
        message = f"Your AdsyClub password reset OTP is: {otp}. Valid for 10 minutes. Do not share this code."
        url = "http://api.smsinbd.com/sms-api/sendsms"
        payload = {
            "api_token": settings.API_SMS,
            "senderid": "8809617614969",
            "contact_number": phone,
            "message": message,
        }

        try:
            # Add timeout to prevent ECONNABORTED errors
            response = requests.get(url, params=payload, timeout=15)

            # Check if response is valid JSON
            try:
                response_data = response.json()
            except json.JSONDecodeError:
                # If response is not JSON, try to parse the text response
                response_text = response.text.strip()
                if response.status_code == 200:
                    # Some SMS APIs return simple text responses for success
                    if (
                        "success" in response_text.lower()
                        or "sent" in response_text.lower()
                    ):
                        return Response(
                            {
                                "message": "OTP sent successfully to your phone number",
                                "method": "phone",
                                "masked_phone": phone[:-4] + "****",
                            },
                            status=status.HTTP_200_OK,
                        )
                    else:
                        return Response(
                            {"error": "Failed to send OTP. Please try again later."},
                            status=status.HTTP_400_BAD_REQUEST,
                        )
                else:
                    return Response(
                        {"error": "SMS service error. Please try again later."},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    )

            # Handle JSON response
            if response_data.get("status") == "success" or response.status_code == 200:
                return Response(
                    {
                        "message": "OTP sent successfully to your phone number",
                        "method": "phone",
                        "masked_phone": phone[:-4] + "****",
                    },
                    status=status.HTTP_200_OK,
                )
            else:
                error_message = response_data.get("message", "Failed to send OTP")
                return Response(
                    {
                        "error": f"SMS delivery failed: {error_message}. Please try again or contact support."
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )

        except requests.exceptions.Timeout:
            return Response(
                {
                    "error": "SMS service is taking too long to respond. Please try again in a few minutes."
                },
                status=status.HTTP_408_REQUEST_TIMEOUT,
            )
        except requests.exceptions.ConnectionError:
            return Response(
                {
                    "error": "Unable to connect to SMS service. Please check your internet connection and try again."
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        except requests.exceptions.RequestException:
            return Response(
                {
                    "error": "SMS service error. Please try again later or contact support."
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    # TODO: Uncomment this section when SMTP is configured
    # elif method == 'email':
    #     try:
    #         from django.core.mail import send_mail
    #         send_mail(    #             'Password Reset OTP - AdsyClub',
    #             f'Your AdsyClub password reset OTP is: {otp}\n\nThis code is valid for 10 minutes. Do not share this code with anyone.\n\nIf you did not request this, please ignore this email.',
    #             settings.DEFAULT_FROM_EMAIL,
    #             [email],
    #             fail_silently=False,
    #         )
    #         return Response({
    #             'message': 'OTP sent successfully to your email address',
    #             'method': 'email',
    #             'masked_email': email[:2] + '*' * (len(email.split('@')[0]) - 2) + '@' + email.split('@')[1],
    #         }, status=status.HTTP_200_OK)
    #     except Exception as e:
    #         return Response({'error': 'Failed to send email. Please try again later.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
def verifyOTP(request):
    phone = request.data.get("phone")
    email = request.data.get("email")
    otp = request.data.get("otp")
    method = request.data.get("method", "phone")

    if not otp:
        return Response(
            {"error": "OTP is required"}, status=status.HTTP_400_BAD_REQUEST
        )

    # Validate OTP format (should be 6 digits)
    otp_str = str(otp).strip()
    if not re.match(r"^\d{6}$", otp_str):
        return Response(
            {"error": "Please enter a valid 6-digit OTP code"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        if method == "phone":
            if not phone:
                return Response(
                    {"error": "Phone number is required"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            # Normalize phone number (same as in sendOTP)
            phone = phone.strip()
            if phone.startswith("+88"):
                phone = phone[3:]
            elif phone.startswith("88"):
                phone = phone[2:]

            user = User.objects.get(phone=phone)
            contact_key = f"otp_attempts_{phone}"
        elif method == "email":
            if not email:
                return Response(
                    {"error": "Email address is required"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            user = User.objects.get(email=email)
            contact_key = f"otp_attempts_{email}"
        else:
            return Response(
                {"error": "Invalid method"}, status=status.HTTP_400_BAD_REQUEST
            )
    except User.DoesNotExist:
        return Response(
            {"error": "User not found. Please check your details and try again."},
            status=status.HTTP_404_NOT_FOUND,
        )

    # Check OTP attempts using Django cache (temporary storage)
    from django.core.cache import cache

    attempts = cache.get(contact_key, 0)

    # Check if OTP matches
    if str(user.otp) == otp_str:
        # Clear attempts on successful verification
        cache.delete(contact_key)

        # Generate reset token
        from rest_framework.authtoken.models import Token

        # Delete any existing tokens for this user
        Token.objects.filter(user=user).delete()
        token, created = Token.objects.get_or_create(user=user)

        return Response(
            {
                "message": "OTP verified successfully",
                "token": token.key,
                "user_id": str(user.id),
            },
            status=status.HTTP_200_OK,
        )
    else:
        # Increment attempt counter
        attempts += 1
        cache.set(contact_key, attempts, timeout=600)  # Store for 10 minutes

        if attempts >= 5:
            # Reset OTP and require new code
            user.otp = "000000"
            user.save()
            cache.delete(contact_key)

            return Response(
                {
                    "error": "Too many invalid attempts. Your verification code has been reset. Please request a new code to continue.",
                    "reset_required": True,
                },
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        else:
            remaining_attempts = 5 - attempts
            return Response(
                {
                    "error": f"Invalid verification code. You have {remaining_attempts} attempt(s) remaining.",
                    "attempts_remaining": remaining_attempts,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def change_password(request):
    user = request.user
    old_password = request.data.get("old_password")
    new_password = request.data.get("new_password")
    print(old_password, new_password)
    # Validate input
    if not old_password or not new_password:
        return Response(
            {"error": "Both old password and new password are required"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Check if old password is correct
    if not check_password(old_password, user.password):
        return Response(
            {"error": "Current password is incorrect"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Set new password
    user.set_password(new_password)
    user.save()

    return Response(
        {"message": "Password changed successfully"}, status=status.HTTP_200_OK
    )


@api_view(["POST"])
def resetPassword(request):
    token_key = request.data.get("token")
    new_password = request.data.get("new_password")

    # Debug logging
    print(f"Reset password request data: {request.data}")
    print(f"Token received: {token_key[:10] + '...' if token_key else 'None'}")
    print(f"Password length: {len(new_password) if new_password else 'None'}")

    if not token_key or not new_password:
        return Response(
            {"error": "Token and new password are required"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Enhanced password validation
    if len(new_password) < 8:
        return Response(
            {"error": "Password must be at least 8 characters long"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Check for basic password strength
    if not re.search(r"[A-Z]", new_password):
        return Response(
            {"error": "Password must contain at least one uppercase letter"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if not re.search(r"[0-9]", new_password):
        return Response(
            {"error": "Password must contain at least one number"},
            status=status.HTTP_400_BAD_REQUEST,
        )
    try:
        from rest_framework.authtoken.models import Token

        token = Token.objects.get(key=token_key)
        user = token.user
        print(f"Token found for user: {user.email}")
    except Token.DoesNotExist:
        print(f"Token not found: {token_key}")
        return Response(
            {
                "error": "Invalid or expired reset token. Please request a new password reset."
            },
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        # Reset password and clear OTP
        user.set_password(new_password)
        user.otp = "000000"  # Clear OTP
        user.save()

        # Delete the token to prevent reuse
        token.delete()

        # Generate new JWT tokens for automatic login
        from rest_framework_simplejwt.tokens import RefreshToken

        from .serializers import UserSerializerGet

        refresh = RefreshToken.for_user(user)
        user_data = UserSerializerGet(user).data

        print(f"Password reset successful for user: {user.email}")
        return Response(
            {
                "message": "Password reset successfully. You are now logged in.",
                "auto_login": True,
                "tokens": {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                },
                "user": user_data,
            },
            status=status.HTTP_200_OK,
        )
    except Exception as e:
        print(f"Error during password reset: {str(e)}")
        return Response(
            {"error": "An error occurred while resetting password. Please try again."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["POST"])
def reset_password_request(request):
    method = request.data.get("method")
    value = request.data.get(method)

    try:
        user = User.objects.get(**{method: value})
        # Generate OTP
        otp = "".join([str(random.randint(0, 9)) for _ in range(6)])
        user.otp = otp
        user.save()

        # Send OTP
        if method == "email":
            send_mail(
                "Password Reset OTP",
                f"Your OTP for password reset is: {otp}",
                settings.DEFAULT_FROM_EMAIL,
                [value],
                fail_silently=False,
            )
        else:
            # Implement SMS sending logic here
            pass

        return Response({"detail": "Reset instructions sent"})
    except User.DoesNotExist:
        return Response(
            {"detail": f"No user found with this {method}"},
            status=status.HTTP_404_NOT_FOUND,
        )


@api_view(["POST"])
def verify_reset_otp(request):
    method = request.data.get("method")
    value = request.data.get(method)
    otp = request.data.get("otp")

    try:
        user = User.objects.get(**{method: value})
        if user.otp != otp:
            return Response(
                {"detail": "Invalid OTP"}, status=status.HTTP_400_BAD_REQUEST
            )
        return Response({"detail": "OTP verified"})
    except User.DoesNotExist:
        return Response({"detail": "User not found"}, status=status.HTTP_404_NOT_FOUND)


@api_view(["GET"])
def subscribeToPro(request):
    user = request.user
    months = request.GET.get("months")
    total = request.GET.get("total")

    if not months or not total:
        return Response(
            {"error": "Both months and total are required"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Check if this is the user's first subscription (only pay commission once)
    is_first_time = not Subscription.objects.filter(user=user).exists()

    # Convert total to Decimal for calculations
    total_decimal = Decimal(total)

    # Create transaction record for the subscription purchase
    Balance.objects.create(
        user=user,
        amount=total_decimal,
        payable_amount=total_decimal,
        transaction_type="pro_subscription",
        completed=True,
        approved=True,
        bank_status="completed",
        description=f"Pro subscription purchase for {months} month(s)",
    )

    # Create the subscription record
    subscription = Subscription.objects.create(user=user, months=months, total=total)

    # Process referral commission for first-time subscribers
    commission_processed = False
    if is_first_time and user.refer:  # Check if user has a referrer
        try:
            referrer = user.refer
            # Calculate 5% commission
            commission_amount = total_decimal * Decimal("0.05")  # 5% commission

            # Update referrer's balance
            referrer.balance += commission_amount
            # Track total commission earned by referrer
            referrer.commission_earned += commission_amount
            referrer.save()

            # Create transaction record
            Balance.objects.create(
                user=referrer,
                to_user=user,
                amount=commission_amount,
                transaction_type="referral_commission",
                completed=True,
                bank_status="completed",
                description=f"Referral commission from {user.name or user.email}'s first Pro subscription",
            )
            commission_processed = True
            print(
                f"Referral commission of {commission_amount} credited to {referrer.email}"
            )
        except Exception as e:
            print(f"Error processing referral commission: {str(e)}")

    # Create notification for pro subscription
    try:
        create_pro_subscription_notification(
            user=user, months=int(months), amount=total_decimal
        )
    except Exception as e:
        print(f"Error creating subscription notification: {str(e)}")

    resp = {
        "message": "Subscription successful",
        "status": "success",
        "subscription_id": subscription.id,
        "commission_processed": commission_processed,
    }
    return Response(resp, status=status.HTTP_200_OK)


@api_view(["POST"])
def set_new_password(request):
    method = request.data.get("method")
    value = request.data.get(method)
    otp = request.data.get("otp")
    password = request.data.get("password")

    try:
        user = User.objects.get(**{method: value})
        if user.otp != otp:
            return Response(
                {"detail": "Invalid OTP"}, status=status.HTTP_400_BAD_REQUEST
            )

        user.set_password(password)
        user.otp = "000000"  # Reset OTP
        user.save()

        return Response({"detail": "Password reset successfully"})
    except User.DoesNotExist:
        return Response({"detail": "User not found"}, status=status.HTTP_404_NOT_FOUND)


class ReceivedTransfersView(generics.ListAPIView):
    """View for seeing all transfers received by the current user"""

    serializer_class = BalanceSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Return all transfers where the current user is the recipient"""
        # Use Django ORM instead of raw SQL for better compatibility with DRF
        return (
            Balance.objects.filter(to_user=self.request.user, completed=True)
            .select_related("user")
            .order_by("-updated_at")
        )


# product


# Product List and Create
class ProductListCreateView(generics.ListCreateAPIView):
    queryset = Product.objects.all().order_by("-created_at")
    serializer_class = ProductSerializer
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.request.method == "GET":
            return [AllowAny()]
        return [IsAuthenticated()]

    def create(self, request, *args, **kwargs):
        # Check product slot limit before creating the product
        user = request.user
        current_product_count = Product.objects.filter(owner=user).count()

        if current_product_count >= user.product_limit:
            return Response(
                {
                    "error": "Product limit reached",
                    "message": f"You have reached your product limit of {user.product_limit}. Please purchase additional product slots to add more products.",
                    "current_count": current_product_count,
                    "limit": user.product_limit,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Extract data from request
        category_data = request.data.pop("category", None)
        images_data = request.data.pop("images", None)
        benefits_data = request.data.pop("benefits", None)
        faqs_data = request.data.pop("faqs", None)
        trust_badges_data = request.data.pop("trust_badges", None)

        # Create product using serializer
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        product = serializer.save(owner=request.user)

        # Process category
        if category_data:
            for category in category_data:
                product_category = ProductCategory.objects.get(id=category)
                product.category.add(product_category)

        # Process images if provided
        if images_data:
            # Handle both list of images and single image
            if not isinstance(images_data, list):
                images_data = [images_data]

            for image_data in images_data:
                try:
                    if isinstance(image_data, str) and image_data.startswith(
                        "data:image"
                    ):
                        # Process base64 image
                        image_file = base64ToFile(image_data)
                        product_media = ProductMedia.objects.create(image=image_file)
                        product.image.add(product_media)
                except Exception as e:
                    # Log error but continue processing
                    print(f"Error processing image: {str(e)}")

        # Process benefits if provided
        if benefits_data and isinstance(benefits_data, list):
            for benefit_data in benefits_data:
                if (
                    isinstance(benefit_data, dict)
                    and "title" in benefit_data
                    and "description" in benefit_data
                ):
                    # Check if benefit already exists
                    benefit, created = ProductBenefit.objects.get_or_create(
                        title=benefit_data["title"],
                        defaults={
                            "description": benefit_data["description"],
                            "icon": benefit_data.get("icon", "i-heroicons-sparkles"),
                        },
                    )
                    if (
                        not created
                        and benefit.description != benefit_data["description"]
                    ):
                        benefit.description = benefit_data["description"]
                        benefit.icon = benefit_data.get("icon", benefit.icon)
                        benefit.save()

                    product.benefits.add(benefit)

        # Process FAQs if provided
        if faqs_data and isinstance(faqs_data, list):
            for faq_data in faqs_data:
                if (
                    isinstance(faq_data, dict)
                    and "label" in faq_data
                    and "content" in faq_data
                ):
                    # Check if FAQ already exists
                    faq, created = ProductFAQ.objects.get_or_create(
                        label=faq_data["label"],
                        defaults={
                            "content": faq_data["content"],
                            "icon": faq_data.get("icon"),
                        },
                    )
                    if not created and faq.content != faq_data["content"]:
                        faq.content = faq_data["content"]
                        faq.icon = faq_data.get("icon", faq.icon)
                        faq.save()

                    product.faqs.add(faq)

        # Process trust badges if provided
        if trust_badges_data and isinstance(trust_badges_data, list):
            for badge_data in trust_badges_data:
                if (
                    isinstance(badge_data, dict)
                    and "id" in badge_data
                    and "text" in badge_data
                ):
                    # Check if badge already exists
                    badge, created = ProductTrustBadge.objects.get_or_create(
                        id=badge_data["id"],
                        defaults={
                            "text": badge_data["text"],
                            "icon": badge_data.get("icon", ""),
                            "enabled": badge_data.get("enabled", True),
                            "description": badge_data.get("description", ""),
                        },
                    )
                    if not created:
                        # Update badge properties if they've changed
                        badge.text = badge_data["text"]
                        badge.icon = badge_data.get("icon", badge.icon)
                        badge.enabled = badge_data.get("enabled", badge.enabled)
                        badge.description = badge_data.get(
                            "description", badge.description
                        )
                        badge.save()

                    product.trust_badges.add(badge)

        # Re-serialize the product to include all data
        updated_serializer = self.get_serializer(product)
        headers = self.get_success_headers(updated_serializer.data)
        return Response(
            updated_serializer.data, status=status.HTTP_201_CREATED, headers=headers
        )


# Product Retrieve, Update, Delete


class ProductDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    lookup_field = "slug"

    def get_permissions(self):
        if self.request.method == "PUT" and self.request.method == "PATCH":
            return [IsAuthenticated()]

        return [AllowAny()]

    def update(self, request, *args, **kwargs):
        try:
            # Extract related data from request
            benefits_data = request.data.pop("benefits", None)
            faqs_data = request.data.pop("faqs", None)
            trust_badges_data = request.data.pop("trustBadges", None)

            # Get the instance to update
            partial = kwargs.pop("partial", False)
            instance = self.get_object()

            # Update the main product data
            serializer = self.get_serializer(
                instance, data=request.data, partial=partial
            )
            serializer.is_valid(raise_exception=True)
            self.perform_update(serializer)

            # Handle benefits if provided
            if benefits_data and isinstance(benefits_data, list):
                # Clear existing benefits if we're replacing them
                instance.benefits.clear()

                for benefit_data in benefits_data:
                    if (
                        isinstance(benefit_data, dict)
                        and "title" in benefit_data
                        and "description" in benefit_data
                    ):
                        # Check if benefit already exists
                        benefit, created = ProductBenefit.objects.get_or_create(
                            title=benefit_data["title"],
                            defaults={
                                "description": benefit_data["description"],
                                "icon": benefit_data.get(
                                    "icon", "i-heroicons-sparkles"
                                ),
                            },
                        )
                        if (
                            not created
                            and benefit.description != benefit_data["description"]
                        ):
                            benefit.description = benefit_data["description"]
                            benefit.icon = benefit_data.get("icon", benefit.icon)
                            benefit.save()

                        instance.benefits.add(benefit)

            # Handle FAQs if provided
            if faqs_data and isinstance(faqs_data, list):
                # Clear existing FAQs if we're replacing them
                instance.faqs.clear()

                for faq_data in faqs_data:
                    if (
                        isinstance(faq_data, dict)
                        and "label" in faq_data
                        and "content" in faq_data
                    ):
                        # Check if FAQ already exists
                        faq, created = ProductFAQ.objects.get_or_create(
                            label=faq_data["label"],
                            defaults={
                                "content": faq_data["content"],
                                "icon": faq_data.get("icon"),
                            },
                        )
                        if not created and faq.content != faq_data["content"]:
                            faq.content = faq_data["content"]
                            faq.icon = faq_data.get("icon", faq.icon)
                            faq.save()

                        instance.faqs.add(faq)

            # Handle trust badges if provided
            if trust_badges_data and isinstance(trust_badges_data, list):
                # Clear existing trust badges if we're replacing them
                instance.trust_badges.clear()

                for badge_data in trust_badges_data:
                    if (
                        isinstance(badge_data, dict)
                        and "id" in badge_data
                        and "text" in badge_data
                    ):
                        # Check if badge already exists
                        badge, created = ProductTrustBadge.objects.get_or_create(
                            id=badge_data["id"],
                            defaults={
                                "text": badge_data["text"],
                                "icon": badge_data.get("icon", ""),
                                "enabled": badge_data.get("enabled", True),
                                "description": badge_data.get("description", ""),
                            },
                        )
                        if not created:
                            # Update badge properties if they've changed
                            badge.text = badge_data["text"]
                            badge.icon = badge_data.get("icon", badge.icon)
                            badge.enabled = badge_data.get("enabled", badge.enabled)
                            badge.description = badge_data.get(
                                "description", badge.description
                            )
                            badge.save()

                        instance.trust_badges.add(badge)

            # Re-fetch the instance with all related fields
            instance = self.get_object()
            result = self.get_serializer(instance).data

            return Response(result)

        except Exception as e:
            print(f"Update error: {str(e)}")
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

    def perform_update(self, serializer):
        serializer.save()

    def perform_destroy(self, instance):
        """
        Check if user is the product owner or admin before allowing deletion
        """
        # Get the user making the request
        user = self.request.user

        # Check if user is authenticated
        if not user.is_authenticated:
            return Response({"error": "You must be logged in to delete a product."})

        # Check if user is either owner or admin
        if user == instance.owner or user.is_staff or user.is_superuser:
            # User is authorized, proceed with deletion
            instance.delete()
        else:
            # User is not authorized
            return Response(
                {
                    "error": "You don't have permission to delete this product. Only the owner or admin can delete products."
                }
            )


# Featured Products


class FeaturedProductsListView(generics.ListAPIView):
    queryset = Product.objects.filter(is_featured=True).order_by("-created_at")
    serializer_class = ProductSerializer


class UserProductPagination(PageNumberPagination):
    page_size = 8  # Default to 8 products per page for my-products
    page_size_query_param = "page_size"
    max_page_size = 100


class SellerOrderPagination(PageNumberPagination):
    page_size = 10  # Default to 10 orders per page for my-orders
    page_size_query_param = "page_size"
    max_page_size = 100


class UserProductsListView(generics.ListAPIView):
    """View for retrieving products owned by the current authenticated user"""

    serializer_class = ProductSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = UserProductPagination

    def get_queryset(self):
        """Return only products owned by the current user with filtering"""
        queryset = Product.objects.filter(owner=self.request.user).order_by(
            "-created_at"
        )

        # Filter by status
        is_active = self.request.query_params.get("is_active", None)
        if is_active is not None:
            queryset = queryset.filter(is_active=is_active.lower() == "true")

        # Filter by stock status
        has_stock = self.request.query_params.get("has_stock", None)
        if has_stock is not None:
            if has_stock.lower() == "true":
                queryset = queryset.filter(quantity__gt=0)
            else:
                queryset = queryset.filter(quantity__lte=0)

        # Search functionality
        search = self.request.query_params.get("search", None)
        if search:
            queryset = queryset.filter(
                Q(name__icontains=search)
                | Q(short_description__icontains=search)
                | Q(description__icontains=search)
                | Q(keywords__icontains=search)
            )
        return queryset


class UserProductStatsView(APIView):
    """View for retrieving product statistics for the current authenticated user"""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Return product statistics for the current user"""
        # Get all user products (unfiltered) for statistics
        all_user_products = Product.objects.filter(owner=request.user)

        # Calculate statistics
        from django.db.models import Case, DecimalField, IntegerField, Sum, When

        stats = {
            "total": all_user_products.count(),
            "active": all_user_products.filter(is_active=True, quantity__gt=0).count(),
            "inactive": all_user_products.filter(is_active=False).count(),
            "out_of_stock": all_user_products.filter(
                is_active=True, quantity__lte=0
            ).count(),
        }

        # Calculate values (using sale_price if available, otherwise regular_price)
        values = all_user_products.aggregate(
            total_value=Sum(
                Case(
                    When(sale_price__gt=0, then="sale_price"),
                    default="regular_price",
                    output_field=DecimalField(),
                )
                * Case(
                    When(quantity__gt=0, then="quantity"),
                    default=0,
                    output_field=IntegerField(),
                )
            ),
            active_value=Sum(
                Case(
                    When(
                        is_active=True,
                        quantity__gt=0,
                        sale_price__gt=0,
                        then="sale_price",
                    ),
                    When(is_active=True, quantity__gt=0, then="regular_price"),
                    default=0,
                    output_field=DecimalField(),
                )
                * Case(
                    When(is_active=True, quantity__gt=0, then="quantity"),
                    default=0,
                    output_field=IntegerField(),
                )
            ),
            inactive_value=Sum(
                Case(
                    When(is_active=False, sale_price__gt=0, then="sale_price"),
                    When(is_active=False, then="regular_price"),
                    default=0,
                    output_field=DecimalField(),
                )
                * Case(
                    When(is_active=False, then="quantity"),
                    default=0,
                    output_field=IntegerField(),
                )
            ),
            out_of_stock_value=Sum(
                Case(
                    When(
                        is_active=True,
                        quantity__lte=0,
                        sale_price__gt=0,
                        then="sale_price",
                    ),
                    When(is_active=True, quantity__lte=0, then="regular_price"),
                    default=0,
                    output_field=DecimalField(),
                )
            ),
        )

        # Handle None values from aggregation
        stats.update(
            {
                "total_value": float(values["total_value"] or 0),
                "active_value": float(values["active_value"] or 0),
                "inactive_value": float(values["inactive_value"] or 0),
                "out_of_stock_value": float(values["out_of_stock_value"] or 0),
            }
        )

        return Response(stats)


class ProductPagination(PageNumberPagination):
    page_size = 25
    page_size_query_param = "page_size"
    max_page_size = 100


# Then update your view to use it


class AllProductsListView(generics.ListAPIView):
    """View for retrieving all products - accessible to anyone"""

    serializer_class = ProductSerializer
    permission_classes = [AllowAny]
    pagination_class = ProductPagination

    def get_queryset(self):
        """Return all available products with optional filtering"""
        # Check if random parameter is provided
        random_products = self.request.query_params.get("random", None)
        limit = self.request.query_params.get("limit", None)

        if random_products and random_products.lower() == "true":
            # Get random products from different categories
            return self.get_random_products_from_categories(limit)

        # Default behavior - return products ordered by creation date
        queryset = Product.objects.filter(is_active=True)

        # Handle ordering parameter
        ordering = self.request.query_params.get("ordering", "-created_at")
        if ordering:
            # Validate ordering parameter to prevent injection
            valid_orderings = [
                "-created_at",
                "created_at",
                "name",
                "-name",
                "sale_price",
                "-sale_price",
                "random",
            ]
            if ordering in valid_orderings:
                if ordering == "random":
                    queryset = queryset.order_by("?")
                else:
                    queryset = queryset.order_by(ordering)
            else:
                # Default fallback
                queryset = queryset.order_by("-created_at")
        else:
            queryset = queryset.order_by("-created_at")

        # Optional filtering by category (ManyToMany) - supports both UUID and slug
        category = self.request.query_params.get("category", None)
        category_slug = self.request.query_params.get("category_slug", None)

        if category and category != "undefined" and category.strip():
            try:
                # Validate that category is a valid UUID before using it
                uuid.UUID(str(category))
                queryset = queryset.filter(category__id=category)
            except (ValueError, AttributeError):
                # Invalid UUID format, try slug filter instead
                queryset = queryset.filter(category__slug=category)
        elif category_slug and category_slug != "undefined" and category_slug.strip():
            # Filter by category slug
            queryset = queryset.filter(category__slug=category_slug)

        # Comprehensive search functionality
        from django.db.models import Q

        # Collect all search parameters
        search = self.request.query_params.get("search", None)
        name = self.request.query_params.get("name", None)
        description = self.request.query_params.get("description", None)
        keywords = self.request.query_params.get("keywords", None)

        # Build a single OR query across all search fields and parameters
        search_conditions = Q()
        search_applied = False

        # If any search parameter is provided, build the OR query
        search_terms = []
        if search and search.strip():
            search_terms.append(search.strip())
        if name and name.strip():
            search_terms.append(name.strip())
        if description and description.strip():
            search_terms.append(description.strip())
        if keywords and keywords.strip():
            search_terms.append(keywords.strip())

        # Remove duplicates while preserving order
        unique_search_terms = list(dict.fromkeys(search_terms))

        if unique_search_terms:
            for term in unique_search_terms:
                # Search across name, description for each term
                term_query = Q(name__icontains=term) | Q(description__icontains=term)

                # Add keywords field if it exists
                try:
                    Product._meta.get_field("keywords")
                    term_query |= Q(keywords__icontains=term)
                except Exception:
                    pass  # keywords field doesn't exist

                # Combine with OR logic
                if not search_applied:
                    search_conditions = term_query
                    search_applied = True
                else:
                    search_conditions |= term_query

            # Apply the combined search query
            if search_applied:
                queryset = queryset.filter(search_conditions)

        # Optional filtering by price range
        min_price = self.request.query_params.get("min_price", None)
        max_price = self.request.query_params.get("max_price", None)

        if min_price:
            queryset = queryset.filter(sale_price__gte=min_price)
        if max_price:
            queryset = queryset.filter(sale_price__lte=max_price)

        # Optional filtering by owner (product seller)
        owner_id = self.request.query_params.get("owner", None)
        if owner_id and owner_id.strip():
            try:
                # Validate that owner_id is a valid UUID before using it
                uuid.UUID(str(owner_id))
                queryset = queryset.filter(owner__id=owner_id)
            except (ValueError, AttributeError):
                # Invalid UUID format, ignore the filter
                pass

        return queryset

    def get_random_products_from_categories(self, limit=None):
        """Get random products from different categories"""
        try:
            limit = int(limit) if limit else 10
        except (ValueError, TypeError):
            limit = 10

        # Get all categories that have products
        categories_with_products = ProductCategory.objects.filter(
            products__is_active=True
        ).distinct()

        if not categories_with_products.exists():
            return Product.objects.none()

        # Convert to list for random selection
        categories_list = list(categories_with_products)

        # Shuffle categories to get random order
        shuffle(categories_list)

        selected_product_ids = []
        products_per_category = (
            max(1, limit // len(categories_list)) if len(categories_list) > 0 else 1
        )
        remaining_slots = limit

        for category in categories_list:
            if remaining_slots <= 0:
                break

            # Get random product IDs from this category
            category_product_ids = list(
                Product.objects.filter(category=category, is_active=True)
                .order_by("?")
                .values_list("id", flat=True)[
                    : min(products_per_category, remaining_slots)
                ]
            )

            selected_product_ids.extend(category_product_ids)
            remaining_slots -= len(category_product_ids)

        # If we still need more products and have remaining slots,
        # fill with any random products
        if remaining_slots > 0:
            additional_product_ids = list(
                Product.objects.filter(is_active=True)
                .exclude(id__in=selected_product_ids)
                .order_by("?")
                .values_list("id", flat=True)[:remaining_slots]
            )
            selected_product_ids.extend(additional_product_ids)

        # Shuffle the final list to mix categories
        shuffle(selected_product_ids)

        # Return queryset with the selected products in random order
        if selected_product_ids:
            # Use Django's __in lookup with preserved order using Case/When
            from django.db.models import Case, IntegerField, When

            preserved_order = Case(
                *[When(pk=pk, then=pos) for pos, pk in enumerate(selected_product_ids)],
                output_field=IntegerField(),
            )
            return Product.objects.filter(id__in=selected_product_ids).order_by(
                preserved_order
            )
        else:
            return Product.objects.none()


class StoreDetailsView(generics.RetrieveUpdateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [AllowAny]
    lookup_field = "store_username"

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()

        # Check if the user is authenticated and is the store owner
        if not request.user.is_authenticated or request.user != instance:
            return Response(
                {"error": "You don't have permission to update this store"},
                status=status.HTTP_403_FORBIDDEN,
            )

        # Handle base64 image data
        data = request.data.copy()

        # Check for store_username uniqueness if it's being updated
        if (
            "store_username" in data
            and data["store_username"] != instance.store_username
        ):
            original_username = data["store_username"]

            # Check if this store_username is already taken by another user
            while (
                User.objects.filter(store_username=data["store_username"])
                .exclude(id=instance.id)
                .exists()
            ):
                # Generate a random number between 1 and 999
                random_suffix = random.randint(1, 999)

                # Trim username if needed to fit within the max length
                base_username = original_username[:16]  # Leave room for suffix
                data["store_username"] = f"{base_username}{random_suffix}"

            # Let the user know if we changed their requested username
            if data["store_username"] != original_username:
                # We'll return this information in the response
                username_changed = True
                new_username = data["store_username"]
            else:
                username_changed = False
                new_username = original_username
        else:
            username_changed = False
            new_username = instance.store_username

        # Process store_logo if provided as base64
        if (
            "store_logo" in data
            and isinstance(data["store_logo"], str)
            and data["store_logo"].startswith("data:image")
        ):
            try:
                data["store_logo"] = base64ToFile(data["store_logo"])
            except Exception as e:
                return Response(
                    {"error": f"Failed to process store logo: {str(e)}"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        # Process store_banner if provided as base64
        if (
            "store_banner" in data
            and isinstance(data["store_banner"], str)
            and data["store_banner"].startswith("data:image")
        ):
            try:
                data["store_banner"] = base64ToFile(data["store_banner"])
            except Exception as e:
                return Response(
                    {"error": f"Failed to process store banner: {str(e)}"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        # Validate and save the data
        serializer = self.get_serializer(instance, data=data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)

        if getattr(instance, "_prefetched_objects_cache", None):
            # If 'prefetch_related' has been applied to a queryset, we need to
            # forcibly invalidate the prefetch cache on the instance.
            instance._prefetched_objects_cache = {}

        # Prepare response with information about username change
        response_data = serializer.data
        if username_changed:
            response_data["username_changed"] = True
            response_data["original_username_request"] = original_username
            response_data["modified_username"] = new_username
            response_data["message"] = (
                f"Your requested username '{original_username}' was already taken. We've assigned '{new_username}' instead."
            )

        return Response(response_data)


class StoreProductsListView(generics.ListAPIView):
    """View for retrieving products by a store's name"""

    serializer_class = ProductSerializer
    permission_classes = [AllowAny]
    pagination_class = ProductPagination

    def get_queryset(self):
        """Return products owned by the user with the specified store_username"""
        store_username = self.kwargs.get("store_username")
        try:
            store_owner = User.objects.get(store_username=store_username)
            return Product.objects.filter(owner=store_owner, is_active=True).order_by(
                "-created_at"
            )
        except User.DoesNotExist:
            return Product.objects.none()


# Category List and Create


class ProductCategoryListCreateView(generics.ListCreateAPIView):
    queryset = ProductCategory.objects.all()
    serializer_class = ProductCategorySerializer
    search_fields = ["name"]

    def get_queryset(self):
        queryset = ProductCategory.objects.all()
        special_offer = self.request.query_params.get("special_offer", None)
        hot_arrival = self.request.query_params.get("hot_arrival", None)

        if special_offer is not None:
            # Convert string to boolean
            is_special = special_offer.lower() == "true"
            queryset = queryset.filter(special_offer=is_special)

        if hot_arrival is not None:
            # Convert string to boolean
            is_hot_arrival = hot_arrival.lower() == "true"
            queryset = queryset.filter(hot_arrival=is_hot_arrival)

        return queryset.order_by("-created_at")

    def get_permissions(self):
        if self.request.method == "GET":
            return []
        else:
            return [IsAuthenticated()]


class ProductCategoryDetailsBySlug(generics.RetrieveAPIView):
    queryset = ProductCategory.objects.all()
    serializer_class = ProductCategorySerializer
    lookup_field = "slug"


# Category Retrieve, Update, Delete


class ProductCategoryDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = ProductCategory.objects.all()
    serializer_class = ProductCategorySerializer


# ORDER VIEWS
class OrderListCreate(generics.ListCreateAPIView):
    """List all orders or create a new order"""

    queryset = Order.objects.all().order_by("-created_at")
    serializer_class = OrderSerializer
    search_fields = ["id", "user__email", "phone"]


class OrderDetail(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update or delete an order"""

    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    lookup_field = "id"


class OrderSearch(generics.ListAPIView):
    """Search for an order by ID"""

    serializer_class = OrderSerializer

    def get_queryset(self):
        order_id = self.request.query_params.get("id")
        if order_id:
            return Order.objects.filter(id=order_id)
        return Order.objects.none()


class UserOrdersList(generics.ListAPIView):
    """List all orders for a specific user"""

    serializer_class = OrderSerializer

    def get_queryset(self):
        user_id = self.kwargs.get("user_id")
        return Order.objects.filter(user__id=user_id).order_by("-created_at")


# ORDER ITEM VIEWS


class OrderItemListCreate(generics.ListCreateAPIView):
    """List all order items or create a new order item"""

    queryset = OrderItem.objects.all().order_by("-created_at")
    serializer_class = OrderItemSerializer
    search_fields = ["id", "product__name"]


class OrderItemDetail(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update or delete an order item"""

    queryset = OrderItem.objects.all()
    serializer_class = OrderItemSerializer
    lookup_field = "id"


class OrderItemSearch(generics.ListAPIView):
    """Search for an order item by ID"""

    serializer_class = OrderItemSerializer

    def get_queryset(self):
        item_id = self.request.query_params.get("id")
        if item_id:
            return OrderItem.objects.filter(id=item_id)
        return OrderItem.objects.none()


class OrderItemsByOrder(generics.ListAPIView):
    """List all items for a specific order"""

    serializer_class = OrderItemSerializer

    def get_queryset(self):
        order_id = self.kwargs.get("order_id")
        return OrderItem.objects.filter(order__id=order_id)


# COMPLEX OPERATIONS


class OrderWithItemsCreate(generics.CreateAPIView):
    """Create an order with multiple items in a single request"""

    serializer_class = OrderSerializer
    # permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        # Extract order and items data
        order_data = request.data.get("order", {})
        items_data = request.data.get("items", [])

        # Set user if not provided in the request
        if "user" not in order_data:
            order_data["user"] = request.user.id

        # Validate payment method
        payment_method = order_data.get("payment_method", "")
        total_amount = Decimal(order_data.get("total", 0))

        # If using account balance, check if user has sufficient funds
        buyer = request.user
        if payment_method == "balance":
            if buyer.balance < total_amount:
                return Response(
                    {"detail": "Insufficient balance to complete this order."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        # Create order first
        order_serializer = OrderSerializer(data=order_data)
        if order_serializer.is_valid():
            order = order_serializer.save()

            # Track payments due to each seller (product owner)
            # Key: seller_id, Value: amount to pay to this seller
            seller_payment_amounts = {}

            # Process all order items
            for item_data in items_data:
                # Associate item with the order
                item_data["order"] = str(order.id)
                item_serializer = OrderItemSerializer(data=item_data)

                if item_serializer.is_valid():
                    # Save the order item
                    order_item = item_serializer.save()

                    # Get the product details
                    try:
                        product = Product.objects.get(id=item_data["product"])
                        product_owner = (
                            product.owner
                        )  # The seller who owns this product

                        # Calculate the amount for this item
                        unit_price = Decimal(
                            str(
                                product.sale_price
                                if product.sale_price
                                else product.regular_price
                            )
                        )
                        quantity = int(item_data.get("quantity", 1))
                        item_subtotal = unit_price * quantity

                        # Calculate delivery fee if applicable
                        delivery_fee = Decimal("0.00")
                        if not product.is_free_delivery:
                            if order_data.get("delivery_location") == "inside_dhaka":
                                delivery_fee = Decimal(
                                    str(product.delivery_fee_inside_dhaka)
                                )
                            else:
                                delivery_fee = Decimal(
                                    str(product.delivery_fee_outside_dhaka)
                                )

                        # Add to the seller's payment amount
                        seller_id = str(product_owner.id)
                        if seller_id not in seller_payment_amounts:
                            seller_payment_amounts[seller_id] = Decimal("0.00")

                        seller_payment_amounts[seller_id] += (
                            item_subtotal + delivery_fee
                        )

                    except Product.DoesNotExist:
                        # If product doesn't exist, delete the order and return error
                        order.delete()
                        return Response(
                            {
                                "detail": f"Product with id {item_data['product']} does not exist"
                            },
                            status=status.HTTP_400_BAD_REQUEST,
                        )
                else:
                    # If any item fails validation, delete the order and return error
                    order.delete()
                    return Response(
                        {
                            "detail": "Invalid item data",
                            "errors": item_serializer.errors,
                        },
                        status=status.HTTP_400_BAD_REQUEST,
                    )
            # Process payment if using balance
            if payment_method == "balance":
                # 1. Deduct total amount from buyer's balance
                buyer.balance -= total_amount
                buyer.save()
                # 2. Create a transaction record for the buyer's payment
                Balance.objects.create(
                    user=buyer,  # The buyer who is making the payment
                    to_user=product_owner,  # No specific seller at this point, just tracking the payment
                    amount=total_amount,  # Negative amount as it's a deduction
                    transaction_type="order_payment",
                    completed=True,
                    bank_status="completed",
                    description=f"Payment for order #{order.id}",
                )
                # 3. Distribute payments to each seller (product owner)
                for seller_id, payment_amount in seller_payment_amounts.items():
                    try:
                        # Get the seller account
                        product_owner = User.objects.get(id=seller_id)

                        # Add payment to seller's balance
                        product_owner.balance += payment_amount
                        product_owner.save()
                        # Create transaction record for the seller's receipt
                        # Balance.objects.create(
                        #     user=product_owner,  # The seller receiving the payment
                        #     to_user=buyer,  # The buyer who made the payment
                        #     amount=payment_amount,  # Positive amount as it's a credit
                        #     transaction_type='order_received',
                        #     completed=True,
                        #     bank_status='completed',
                        #     description=f"Payment received for order #{order.id}"
                        # )

                    except User.DoesNotExist:
                        return Response(
                            {
                                "error": f"Failed to credit seller {seller_id} for order {order.id}"
                            }
                        )

            # Create notifications for all sellers regardless of payment method
            for seller_id, payment_amount in seller_payment_amounts.items():
                try:
                    # Get the seller account
                    product_owner = User.objects.get(id=seller_id)

                    # Create notification for each seller who received an order
                    try:
                        create_order_notification(
                            user=product_owner,  # Send to seller, not buyer
                            order_id=str(order.id),
                            total_amount=payment_amount,  # Amount this seller received
                        )
                        print(
                            f"✓ Order notification created for seller {product_owner.email}: ৳{payment_amount}"
                        )
                    except Exception as e:
                        print(
                            f"Error creating order notification for seller {seller_id}: {str(e)}"
                        )

                except User.DoesNotExist:
                    print(
                        f"Error: Seller with id {seller_id} does not exist for order {order.id}"
                    )

            # Return the complete order details
            return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)

        # Return validation errors if order serializer is invalid
        return Response(order_serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SellerOrdersView(generics.ListAPIView):
    """View for retrieving orders containing products owned by the authenticated user"""

    serializer_class = SellerOrderSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = SellerOrderPagination

    def get_queryset(self):
        """
        Return orders that contain at least one product owned by the current user with filtering
        """
        # Get IDs of products owned by the current user
        user_product_ids = Product.objects.filter(owner=self.request.user).values_list(
            "id", flat=True
        )

        # Find order items that contain these products
        order_ids = (
            OrderItem.objects.filter(product_id__in=user_product_ids)
            .values_list("order_id", flat=True)
            .distinct()
        )

        # Get the base queryset
        queryset = Order.objects.filter(id__in=order_ids).order_by("-created_at")

        # Filter by status
        status_filter = self.request.query_params.get("status", None)
        if status_filter and status_filter != "all":
            queryset = queryset.filter(order_status=status_filter)

        # Search functionality
        search = self.request.query_params.get("search", None)
        if search:
            queryset = queryset.filter(
                Q(order_number__icontains=search)
                | Q(name__icontains=search)
                | Q(email__icontains=search)
            )
        return queryset


class SellerOrderStatsView(APIView):
    """View for retrieving order statistics for the current authenticated user's products"""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Return order statistics for the current user's products"""
        # Get IDs of products owned by the current user
        user_product_ids = Product.objects.filter(owner=request.user).values_list(
            "id", flat=True
        )

        # Find order items that contain these products
        order_ids = (
            OrderItem.objects.filter(product_id__in=user_product_ids)
            .values_list("order_id", flat=True)
            .distinct()
        )

        # Get all orders containing user's products
        all_orders = Order.objects.filter(id__in=order_ids)

        # Calculate statistics
        from django.db.models import Sum

        stats = {
            "total": all_orders.count(),
            "pending": all_orders.filter(order_status="pending").count(),
            "processing": all_orders.filter(order_status="processing").count(),
            "delivered": all_orders.filter(order_status="delivered").count(),
        }
        # Calculate amounts
        amounts = all_orders.aggregate(
            total_amount=Sum("total"),
            pending_amount=Sum("total", filter=Q(order_status="pending")),
            processing_amount=Sum("total", filter=Q(order_status="processing")),
            delivered_amount=Sum("total", filter=Q(order_status="delivered")),
        )

        # Handle None values from aggregation
        stats.update(
            {
                "total_amount": float(amounts["total_amount"] or 0),
                "pending_amount": float(amounts["pending_amount"] or 0),
                "processing_amount": float(amounts["processing_amount"] or 0),
                "delivered_amount": float(amounts["delivered_amount"] or 0),
            }
        )

        return Response(stats)


class OrderWithItemsUpdate(generics.UpdateAPIView):
    """Update an order by adding new items, updating quantities, or removing items"""

    serializer_class = OrderSerializer
    queryset = Order.objects.all()
    lookup_field = "id"
    permission_classes = [IsAuthenticated]

    def update(self, request, *args, **kwargs):
        order = self.get_object()
        items_data = request.data.get("items", [])

        try:
            seller_objects = {}  # Store seller objects instead of string IDs
            total_additional_amount = Decimal("0.00")
            items_to_remove = []

            # Process all items
            for item_data in items_data:
                product_id = item_data.get("product")
                new_quantity = int(item_data.get("quantity", 1))

                try:
                    # Check if this product already exists in the order
                    existing_item = OrderItem.objects.filter(
                        order=order, product_id=product_id
                    ).first()

                    product = Product.objects.get(id=product_id)
                    unit_price = Decimal(
                        str(
                            product.sale_price
                            if product.sale_price
                            else product.regular_price
                        )
                    )

                    # Get seller directly from product
                    seller = product.owner
                    seller_key = seller.pk

                    if existing_item:
                        # Handle existing item update
                        old_quantity = existing_item.quantity
                        quantity_diff = new_quantity - old_quantity

                        # If quantity is 0, mark for removal
                        if new_quantity == 0:
                            items_to_remove.append(existing_item)
                            price_difference = -unit_price * old_quantity

                            # Update seller amounts (negative since removing item)
                            if seller_key not in seller_objects:
                                seller_objects[seller_key] = {
                                    "user": seller,
                                    "amount": Decimal("0.00"),
                                }
                            seller_objects[seller_key]["amount"] += price_difference
                            total_additional_amount += price_difference
                        elif quantity_diff != 0:
                            # Update quantity and calculate price difference
                            price_difference = unit_price * quantity_diff

                            # Store seller object and update payment amounts
                            if seller_key not in seller_objects:
                                seller_objects[seller_key] = {
                                    "user": seller,
                                    "amount": Decimal("0.00"),
                                }
                            seller_objects[seller_key]["amount"] += price_difference
                            total_additional_amount += price_difference

                            # Update the order item quantity
                            existing_item.quantity = new_quantity
                            existing_item.save()
                    else:
                        # Skip if trying to add an item with quantity 0
                        if new_quantity == 0:
                            continue

                        # Add new item to order
                        new_item_data = {
                            "order": order.id,
                            "product": product_id,
                            "quantity": new_quantity,
                            "price": unit_price,
                        }

                        item_serializer = OrderItemSerializer(data=new_item_data)
                        if item_serializer.is_valid():
                            order_item = item_serializer.save()

                            item_subtotal = unit_price * new_quantity

                            # Calculate delivery fee if applicable
                            delivery_fee = Decimal("0.00")
                            if not product.is_free_delivery:
                                if order.delivery_location == "inside_dhaka":
                                    delivery_fee = Decimal(
                                        str(product.delivery_fee_inside_dhaka)
                                    )
                                else:
                                    delivery_fee = Decimal(
                                        str(product.delivery_fee_outside_dhaka)
                                    )

                            # Store seller object and update payment amounts
                            if seller_key not in seller_objects:
                                seller_objects[seller_key] = {
                                    "user": seller,
                                    "amount": Decimal("0.00"),
                                }
                            seller_objects[seller_key]["amount"] += (
                                item_subtotal + delivery_fee
                            )
                            total_additional_amount += item_subtotal + delivery_fee
                        else:
                            return Response(
                                {
                                    "error": "Invalid item data",
                                    "errors": item_serializer.errors,
                                },
                                status=status.HTTP_400_BAD_REQUEST,
                            )

                except Product.DoesNotExist:
                    return Response(
                        {"error": f"Product with id {product_id} does not exist"},
                        status=status.HTTP_404_NOT_FOUND,
                    )

            # Delete items marked for removal
            for item in items_to_remove:
                item.delete()  # Process payment adjustments
            # Use the order's user as the buyer, not the currently logged in user
            buyer = order.user
            if total_additional_amount > 0:
                # Handle additional payment needed
                if order.payment_method == "balance":
                    if buyer.balance < total_additional_amount:
                        return Response(
                            {"error": "Insufficient balance for additional items"},
                            status=status.HTTP_400_BAD_REQUEST,
                        )

                    # Deduct additional amount from buyer's balance
                    buyer.balance -= total_additional_amount
                    buyer.save()  # Create transaction record for the buyer's payment
                    Balance.objects.create(
                        user=buyer,
                        to_user=None,  # No specific seller at this point
                        amount=-total_additional_amount,
                        transaction_type="order_update",
                        completed=True,
                        bank_status="completed",
                        description=f"Payment adjustment for order {order.id}",
                    )

                    # Distribute additional payments to sellers
                    for seller_data in seller_objects.values():
                        seller = seller_data["user"]
                        payment_amount = seller_data["amount"]

                        if payment_amount > 0:
                            # Update seller balance (only for positive adjustments)
                            seller.balance += payment_amount
                            seller.save()  # Create transaction record

            elif total_additional_amount < 0 and order.payment_method == "balance":
                # Handle refund for reduced items
                refund_amount = -total_additional_amount  # Make positive for refund

                # Add refund to buyer's balance
                buyer.balance += refund_amount
                buyer.save()  # Create transaction record for refund
                Balance.objects.create(
                    user=buyer,
                    # No specific seller is needed here as this is a refund to the buyer
                    to_user=None,
                    amount=refund_amount,
                    transaction_type="order_refund",
                    completed=True,
                    bank_status="completed",
                    description=f"Refund for order {order.id} updates",
                )

                # Handle seller balance adjustments for negative amounts
                for seller_data in seller_objects.values():
                    seller = seller_data["user"]
                    payment_amount = seller_data["amount"]

                    if payment_amount < 0:
                        # Deduct from seller balance (negative adjustment becomes positive)
                        deduction_amount = -payment_amount
                        seller.balance -= deduction_amount
                        seller.save()
                        # Create transaction record
                        Balance.objects.create(
                            user=seller,
                            to_user=buyer,
                            amount=-deduction_amount,  # Negative amount for deduction
                            transaction_type="order_deduction",
                            completed=True,
                            bank_status="completed",
                            description=f"Payment adjustment for order {order.id}",
                        )

            # Update order total
            order.total += total_additional_amount
            order.save()

            # Recalculate order total from scratch to ensure accuracy
            order_items = OrderItem.objects.filter(order=order)
            calculated_total = Decimal("0.00")
            for order_item in order_items:
                item_price = order_item.price * order_item.quantity
                calculated_total += item_price

            # Update with calculated total if different
            if calculated_total != order.total:
                order.total = calculated_total
                order.save()

            return Response(OrderSerializer(order).data, status=status.HTTP_200_OK)

        except Exception as e:
            import traceback

            print(f"Error in order update: {str(e)}")
            print(traceback.format_exc())
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET"])
@permission_classes([AllowAny])
def check_store_username_availability(request):
    """
    Check if a store_username is available

    Query param: username - The store username to check
    Returns: JSON with availability status
    """
    username = request.query_params.get("username", None)

    if not username:
        return Response(
            {"error": "Username parameter is required"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Check if username exists
    exists = User.objects.filter(store_username=username).exists()

    if exists:
        # If username exists, suggest alternatives
        import random

        original_username = username
        suggestions = []

        # Generate 3 alternative suggestions
        for _ in range(3):
            # Trim username if needed to fit the max length with suffix
            # Leave room for random suffix
            base_username = original_username[:16]
            random_suffix = random.randint(100, 999)
            suggestion = f"{base_username}{random_suffix}"
            suggestions.append(suggestion)

        return Response(
            {
                "available": False,
                "message": "This store username is already taken",
                "suggestions": suggestions,
            }
        )

    return Response({"available": True, "message": "Store username is available"})


class BannerImageListView(generics.ListAPIView):
    """
    View to retrieve all banners.
    """

    queryset = BannerImage.objects.all()
    serializer_class = BannerImageSerializer


class ShopBannerImageListView(generics.ListAPIView):
    """
    View to retrieve all shop banners.
    """

    queryset = ShopBannerImage.objects.all()
    serializer_class = ShopBannerImageSerializer


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def purchase_product_slots(request):
    """
    Endpoint to handle the purchase of additional product slots.
    """
    package_id = request.data.get("package_id")
    slot_count = request.data.get("slot_count", 0)
    cost = request.data.get("cost", 0)

    if not package_id and (not slot_count or not cost):
        return Response(
            {"success": False, "message": "Invalid package ID or slot count/cost"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user = request.user

    # If package_id is provided, validate against package in database
    valid_cost = False
    if package_id:
        try:
            package = ProductSlotPackage.objects.get(id=package_id)
            slot_count = package.slots
            cost = package.price
            valid_cost = True
        except ProductSlotPackage.DoesNotExist:
            return Response(
                {"success": False, "message": "Invalid package ID"},
                status=status.HTTP_400_BAD_REQUEST,
            )
    else:
        # For backward compatibility, check hardcoded values
        if slot_count == 5 and cost == 500:
            valid_cost = True
        elif slot_count == 10 and cost == 900:
            valid_cost = True
        elif slot_count == 20 and cost == 1600:
            valid_cost = True

    if not valid_cost:
        return Response(
            {"success": False, "message": "Invalid cost for selected slot count"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Check if user has sufficient balance
    if user.balance < cost:
        return Response(
            {"success": False, "message": "Insufficient balance"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        # Update user's product limit and balance
        user.product_limit += slot_count
        user.balance -= cost
        user.save()

        # Return updated user info
        return Response(
            {
                "success": True,
                "message": f"Successfully purchased {slot_count} product slots",
                "data": {"product_limit": user.product_limit, "balance": user.balance},
            }
        )
    except Exception as e:
        return Response(
            {"success": False, "message": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def referred_users(request):
    current_user = request.user
    referred_users = User.objects.filter(refer=current_user).order_by("-date_joined")
    total_referred = referred_users.count()
    total_earned = current_user.commission_earned

    serializer = UserSerializer(referred_users, many=True)

    return Response(
        {
            "total_referred": total_referred,
            "total_earned": total_earned,
            "referred_users": serializer.data,
        },
        status=status.HTTP_200_OK,
    )


class BNLogoView(generics.ListAPIView):
    queryset = BNLogo.objects.all().order_by("-created_at")
    serializer_class = BNLogoSerializer


class NewsLogoView(generics.ListAPIView):
    queryset = NewsLogo.objects.all().order_by("-created_at")
    serializer_class = NewsLogoSerializer


@api_view(["GET"])
def product_order_count(request, product_id):
    """
    Get the number of orders for a specific product
    """
    product = get_object_or_404(Product, id=product_id)

    data = {
        "product_id": str(product.id),
        "product_name": product.name,
        "order_count": product.order_count,
        "total_units_sold": product.total_items_ordered,
    }
    return Response(data, status=status.HTTP_200_OK)


class DiamondPackageListView(generics.ListAPIView):
    queryset = DiamondPackages.objects.all()
    serializer_class = DiamondPackagesSerializer


class ProductSlotPackageListView(generics.ListAPIView):
    queryset = ProductSlotPackage.objects.all()
    serializer_class = ProductSlotPackageSerializer
    permission_classes = [AllowAny]


class DiamondTransactionListView(generics.ListAPIView):
    serializer_class = DiamondTransactionSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = SmallResultsSetPagination

    def get_queryset(self):
        return DiamondTransaction.objects.filter(user=self.request.user)


class PurchaseDiamondsView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        data = request.data
        data["user"] = request.user.id
        data["transaction_type"] = "purchase"
        purchage_diamonds_serializer = DiamondTransactionSerializer(data=data)
        if purchage_diamonds_serializer.is_valid():
            purchage_diamonds_serializer.save()
            return Response(
                purchage_diamonds_serializer.data, status=status.HTTP_201_CREATED
            )
        else:
            print(purchage_diamonds_serializer.errors)
            return Response(
                purchage_diamonds_serializer.errors, status=status.HTTP_400_BAD_REQUEST
            )
        # try:
        #     amount = int(request.data.get('amount', 0))
        #     cost = float(request.data.get('cost', 0))

        #     if amount <= 0:
        #         return Response({'error': 'Diamond amount must be greater than zero'}, status=400)

        #     if cost <= 0:
        #         return Response({'error': 'Cost must be greater than zero'}, status=400)

        #     # Create diamond transaction
        #     diamond_transaction = DiamondTransaction.objects.create(
        #         user=request.user.id,
        #         transaction_type='purchase',
        #         amount=amount,
        #         cost=cost
        #     )

        #     # Return updated user balance information
        #     return Response({
        #         'success': True,
        #         'message': f'Successfully purchased {amount} diamonds',
        #         'balance': request.user.balance,
        #         'diamond_balance': request.user.diamond_balance,
        #         'transaction': {
        #             'id': diamond_transaction.id,
        #             'amount': diamond_transaction.amount,
        #             'cost': diamond_transaction.cost,
        #             'created_at': diamond_transaction.created_at
        #         }
        #     })
        # except ValidationError as e:
        #     return Response({'error': str(e)}, status=400)
        # except Exception as e:
        #     return Response({'error': str(e)}, status=500)


class SendDiamondGiftView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            # Log request data for debugging
            print("Diamond gift request received:", request.data)

            # Convert amount to integer, handling potential string input
            try:
                amount = int(request.data.get("amount", 0))
            except (TypeError, ValueError):
                return Response({"error": "Invalid diamond amount"}, status=400)

            recipient_id = request.data.get("recipientId")
            post_id = request.data.get("postId")
            message = request.data.get("message", "")

            # Basic validation
            if amount <= 0:
                return Response(
                    {"error": "Diamond amount must be greater than zero"}, status=400
                )

            if not recipient_id:
                return Response({"error": "Recipient ID is required"}, status=400)

            # Find recipient user
            try:
                recipient = User.objects.get(id=recipient_id)
                print(f"Recipient found: {recipient.id}, {recipient.email}")
            except User.DoesNotExist:
                return Response({"error": "Recipient user not found"}, status=404)

            # Check if the user has enough diamonds
            sender = request.user

            print(
                f"Sender diamond balance: {sender.diamond_balance}, Trying to send: {amount}"
            )

            if sender.diamond_balance is None or sender.diamond_balance < amount:
                return Response({"error": "Insufficient diamond balance"}, status=400)

            # Transfer diamonds from sender to recipient
            sender.diamond_balance -= amount
            sender.save()

            # Initialize recipient diamond_balance if it's NULL
            if recipient.diamond_balance is None:
                recipient.diamond_balance = 0

            recipient.diamond_balance += amount
            recipient.save()

            # Create diamond transaction record
            diamond_transaction = DiamondTransaction.objects.create(
                user=sender,
                to_user=recipient,
                transaction_type="gift",
                amount=amount,
                post_id=post_id,
                cost=0,  # No cost for gifting, already paid when purchased
                description=message,
                completed=True,
                approved=True,
            )

            # Create a comment on the post if post_id exists
            gift_comment = None
            comment_data = None

            if post_id:
                try:
                    # Import the models with proper exception handling
                    try:
                        from business_network.models import (
                            BusinessNetworkPost,
                            BusinessNetworkPostComment,
                        )
                        from business_network.serializers import (
                            BusinessNetworkPostCommentSerializer,
                        )
                    except ImportError as e:
                        print(f"Import error: {str(e)}")
                        # Continue without creating comment if imports fail
                        pass
                    else:
                        # Find the post
                        post = BusinessNetworkPost.objects.get(id=post_id)

                        # Format gift message with emoji
                        formatted_message = (
                            message.strip()
                            if message.strip()
                            else f"Sent {amount} diamonds as a gift! ✨"
                        )

                        # Create comment with gift flag
                        gift_comment = BusinessNetworkPostComment.objects.create(
                            post=post,
                            author=sender,
                            content=formatted_message,
                            is_gift_comment=True,
                            diamond_amount=amount,
                        )

                        # Serialize comment data
                        comment_data = BusinessNetworkPostCommentSerializer(
                            gift_comment
                        ).data

                except BusinessNetworkPost.DoesNotExist:
                    print(f"Post not found: {post_id}")
                    # Continue without creating comment if post doesn't exist
                    pass
                except Exception as e:
                    print(f"Error creating gift comment: {str(e)}")
                    # Continue without comment if there's an error
                    pass

            # Return updated user balance information
            response_data = {
                "success": True,
                "message": f"Successfully sent {amount} diamonds to {recipient.name or recipient.username or recipient.email}",
                "sender_diamond_balance": sender.diamond_balance,
                "transaction_id": str(diamond_transaction.id),
            }

            # Add comment data if created
            if comment_data:
                response_data["comment"] = comment_data

            return Response(response_data)

        except Exception as e:
            import traceback

            print(f"Diamond gift error: {str(e)}")
            print(traceback.format_exc())
            return Response({"error": str(e)}, status=500)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def commission_history(request):
    """Get detailed commission history breakdown by service type"""
    current_user = request.user

    # Get all commission bonuses for the current user
    commissions = ReferBonus.objects.filter(user=current_user).order_by("-created_at")

    # Aggregate data by commission type
    commission_stats = {
        "gig_completion": {
            "count": 0,
            "total_amount": Decimal("0.00"),
            "rate": "5%",
            "transactions": [],
        },
        "pro_subscription": {
            "count": 0,
            "total_amount": Decimal("0.00"),
            "rate": "20%",
            "transactions": [],
        },
        "gold_sponsor": {
            "count": 0,
            "total_amount": Decimal("0.00"),
            "rate": "20%",
            "transactions": [],
        },
    }

    # Process each commission
    for commission in commissions:
        commission_type = commission.commission_type
        if commission_type in commission_stats:
            commission_stats[commission_type]["count"] += 1
            commission_stats[commission_type]["total_amount"] += commission.amount

            # Add transaction details
            transaction_data = {
                "id": commission.id,
                "date": commission.created_at,
                "amount": float(commission.amount),
                "base_amount": float(commission.base_amount),
                "commission_rate": float(commission.commission_rate),
                "referred_user": {
                    "id": commission.referred_user.id
                    if commission.referred_user
                    else None,
                    "name": f"{commission.referred_user.first_name} {commission.referred_user.last_name}".strip()
                    if commission.referred_user and commission.referred_user.first_name
                    else commission.referred_user.username
                    if commission.referred_user
                    else "Unknown User",
                    "email": commission.referred_user.email
                    if commission.referred_user
                    else None,
                },
                "description": commission.description or "",
                "completed": commission.completed,
            }
            commission_stats[commission_type]["transactions"].append(transaction_data)

    # Convert Decimal to float for JSON serialization
    for commission_type in commission_stats:
        commission_stats[commission_type]["total_amount"] = float(
            commission_stats[commission_type]["total_amount"]
        )

    # Calculate totals
    total_commissions = commissions.count()
    total_earned = float(current_user.commission_earned)

    return Response(
        {
            "total_commissions": total_commissions,
            "total_earned": total_earned,
            "commission_breakdown": commission_stats,
            "recent_transactions": [
                {
                    "id": c.id,
                    "date": c.created_at,
                    "type": c.get_commission_type_display(),
                    "type_code": c.commission_type,
                    "amount": float(c.amount),
                    "referred_user": {
                        "name": f"{c.referred_user.first_name} {c.referred_user.last_name}".strip()
                        if c.referred_user and c.referred_user.first_name
                        else c.referred_user.username
                        if c.referred_user
                        else "Unknown User",
                        "email": c.referred_user.email if c.referred_user else None,
                    },
                    "commission_rate": float(c.commission_rate),
                }
                for c in commissions[:10]  # Latest 10 transactions
            ],
        },
        status=status.HTTP_200_OK,
    )


@api_view(["GET"])
def platform_referral_stats(request):
    """Get platform-wide referral statistics for public display"""
    try:
        # Get total active referrers (users who have made at least one referral)
        active_referrers = User.objects.filter(refer_count__gt=0).count()

        # Get top earner commission amount
        top_earner = (
            User.objects.filter(commission_earned__gt=0)
            .order_by("-commission_earned")
            .first()
        )
        top_earner_amount = float(top_earner.commission_earned) if top_earner else 0

        # Calculate total commissions paid out
        total_commissions = ReferBonus.objects.filter(completed=True).count()

        # Get average payout time (for now, we'll use a static value as payout time tracking needs more implementation)
        # This could be calculated from actual payout data in the future
        quick_payout_time = "24hr"

        return Response(
            {
                "active_referrers": active_referrers,
                "top_earner_amount": top_earner_amount,
                "total_commissions": total_commissions,
                "quick_payout_time": quick_payout_time,
                "commission_rates": {
                    "gig_completion": "5%",
                    "pro_subscription": "20%",
                    "gold_sponsor": "20%",
                },
            },
            status=status.HTTP_200_OK,
        )

    except Exception as e:
        print(f"Error fetching platform referral stats: {str(e)}")
        return Response(
            {"error": "Failed to fetch platform statistics"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


class EshopBannerListView(generics.ListAPIView):
    """
    View to retrieve all eShop banners.
    """

    serializer_class = EshopBannerSerializer

    def get_queryset(self):
        device_type = self.request.GET.get("device_type", "all")
        queryset = EshopBanner.objects.filter(is_active=True)

        if device_type == "mobile":
            queryset = queryset.filter(device_type__in=["all", "mobile"])
        elif device_type == "desktop":
            queryset = queryset.filter(device_type__in=["all", "desktop"])

        return queryset.order_by("order", "-created_at")


class MobileBannerListView(generics.ListAPIView):
    """
    Optimized view specifically for mobile banners
    """

    serializer_class = MobileBannerSerializer

    def get_queryset(self):
        return EshopBanner.objects.filter(
            is_active=True, device_type__in=["all", "mobile"]
        ).order_by("order", "-created_at")


@api_view(["GET"])
def get_latest_android_app(request):
    """
    Get the latest active Android app version information
    """
    try:
        # Get the active app version (should be only one due to model's save method)
        latest_version = AndroidAppVersion.objects.filter(is_active=True).first()

        if not latest_version:
            # Fallback to the version with highest version code
            latest_version = AndroidAppVersion.objects.order_by("-version_code").first()
        if not latest_version:
            return Response(
                {
                    "error": "No app version found",
                    "message": "Please configure an app version in the admin panel",
                },
                status=404,
            )

        serializer = AndroidAppVersionSerializer(latest_version)
        return Response(serializer.data)
    except Exception as e:
        return Response(
            {"error": str(e), "message": "Error retrieving app version information"},
            status=500,
        )


class AILinkView(generics.ListAPIView):
    """
    View to retrieve AI link information.
    """

    queryset = AILink.objects.all()
    serializer_class = AILinkSerializer
    permission_classes = [AllowAny]


# Utility functions for creating notifications


def create_notification(
    user, notification_type, title, message, amount=None, reference_id=None
):
    """
    Create a notification for a specific user or global notification
    """
    return AdminNotice.objects.create(
        user=user,
        notification_type=notification_type,
        title=title,
        message=message,
        amount=amount,
        reference_id=reference_id,
    )


def create_order_notification(user, order_id, total_amount):
    """Create notification for new order received"""
    title = f"New Order Received #{order_id}"
    message = f"You have received a new order worth ৳{total_amount}. Check your shop manager for details."
    return create_notification(
        user=user,
        notification_type="order_received",
        title=title,
        message=message,
        amount=total_amount,
        reference_id=str(order_id),
    )


def create_withdraw_notification(user, amount, transaction_id):
    """Create notification for successful withdrawal"""
    title = "Withdrawal Successful"
    message = f"Your withdrawal of ৳{amount} has been processed successfully."
    return create_notification(
        user=user,
        notification_type="withdraw_successful",
        title=title,
        message=message,
        amount=amount,
        reference_id=transaction_id,
    )


def create_mobile_recharge_notification(user, amount, phone_number, reference_id=None):
    """Create notification for successful mobile recharge"""
    title = "Mobile Recharge Successful"
    message = f"Your mobile recharge of ৳{amount} for {phone_number} has been completed successfully."
    return create_notification(
        user=user,
        notification_type="mobile_recharge_successful",
        title=title,
        message=message,
        amount=amount,
        reference_id=reference_id or phone_number,
    )


def create_transfer_sent_notification(user, amount, recipient_name, transaction_id):
    """Create notification for money transfer sent"""
    title = "Money Transfer Sent"
    message = f"You have successfully sent ৳{amount} to {recipient_name}."
    return create_notification(
        user=user,
        notification_type="transfer_sent",
        title=title,
        message=message,
        amount=amount,
        reference_id=transaction_id,
    )


def create_transfer_received_notification(user, amount, sender_name, transaction_id):
    """Create notification for money transfer received"""
    title = "Money Transfer Received"
    message = f"You have received ৳{amount} from {sender_name}."
    return create_notification(
        user=user,
        notification_type="transfer_received",
        title=title,
        message=message,
        amount=amount,
        reference_id=transaction_id,
    )


def create_deposit_notification(user, amount, transaction_id):
    """Create notification for successful deposit"""
    title = "Deposit Successful"
    message = f"Your deposit of ৳{amount} has been processed successfully."
    return create_notification(
        user=user,
        notification_type="deposit_successful",
        title=title,
        message=message,
        amount=amount,
        reference_id=transaction_id,
    )


def create_pro_subscription_notification(user, months, amount):
    """Create notification for pro subscription activation"""
    title = "Pro Subscription Activated"
    message = f"Your Pro subscription for {months} month(s) has been activated successfully. Enjoy premium features!"
    return create_notification(
        user=user,
        notification_type="pro_subscribed",
        title=title,
        message=message,
        amount=amount,
        reference_id=f"{months}_months",
    )


def create_pro_expiring_notification(user, days_remaining):
    """Create notification for pro subscription expiring warning"""
    title = "Pro Subscription Expiring Soon"
    message = f"Your Pro subscription will expire in {days_remaining} days. Renew now to continue enjoying premium features."
    return create_notification(
        user=user,
        notification_type="pro_expiring",
        title=title,
        message=message,
        reference_id=str(days_remaining),
    )


def create_gig_posted_notification(user, gig_id, gig_title):
    """Create notification for successfully posted gig"""
    title = "Gig Posted Successfully"
    message = f"Your gig '{gig_title}' has been posted successfully and is pending for review by our admin team."
    return create_notification(
        user=user,
        notification_type="gig_posted",
        title=title,
        message=message,
        reference_id=str(gig_id),
    )


def create_gig_approved_notification(user, gig_id, gig_title, reference_id=None):
    """Create notification for approved gig"""
    title = "Gig Approved by Admin"
    message = f"Great news! Your gig '{gig_title}' has been approved by our admin team and is now live for workers to apply."
    return create_notification(
        user=user,
        notification_type="gig_approved",
        title=title,
        message=message,
        reference_id=reference_id or str(gig_id),
    )


def create_gig_rejected_notification(user, gig_id, gig_title, reference_id=None):
    """Create notification for rejected gig"""
    title = "Gig Rejected by Admin"
    message = f"We're sorry, but your gig '{gig_title}' has been rejected by our admin team. Please review our gig posting guidelines and try again."
    return create_notification(
        user=user,
        notification_type="gig_rejected",
        title=title,
        message=message,
        reference_id=reference_id or str(gig_id),
    )


# for frontend


def index(request, **args):
    """
    Handle frontend routing - redirect to Nuxt.js frontend in development
    or serve built frontend files in production
    """
    # Check if this is an API request
    if request.path.startswith("/api/"):
        return JsonResponse({"error": "Invalid API endpoint"}, status=404)

    # In development, try to redirect to Nuxt.js dev server
    if settings.DEBUG:
        frontend_url = "http://localhost:3000"

        # For now, render the fallback template instead of redirecting
        # to avoid redirect loops if frontend is not running
        try:
            return render(request, "index.html")
        except:
            # If template rendering fails, return JSON response
            return JsonResponse(
                {
                    "message": "AdsyClub API Backend",
                    "frontend_url": frontend_url,
                    "requested_path": request.path,
                    "note": "Frontend should be running on port 3000",
                }
            )

    # In production, you would serve the built Nuxt.js files
    return JsonResponse(
        {
            "message": "AdsyClub API Backend",
            "frontend_url": "http://localhost:3000",
            "requested_path": request.path,
        }
    )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def markAdminNoticeAsRead(request, notice_id):
    try:
        notice = AdminNotice.objects.get(id=notice_id)

        # Check if user can mark this notice as read (either global or user-specific)
        if notice.user and notice.user != request.user:
            return Response(
                {"error": "You don't have permission to mark this notice as read"},
                status=status.HTTP_403_FORBIDDEN,
            )

        notice.is_read = True
        notice.save()

        return Response({"message": "Notice marked as read"}, status=status.HTTP_200_OK)
    except AdminNotice.DoesNotExist:
        return Response({"error": "Notice not found"}, status=status.HTTP_404_NOT_FOUND)


class CountryVersionListView(generics.ListAPIView):
    """
    View to retrieve country version information.
    """

    queryset = CountryVersion.objects.all()
    serializer_class = CountryVersionSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        # Optionally filter by country code if provided
        country_code = self.request.query_params.get("country_code", None)
        if country_code:
            return self.queryset.filter(country__code=country_code)
        return self.queryset.all()
