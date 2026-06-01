import base64
import json
import random
import re
import uuid
from decimal import Decimal, InvalidOperation
from random import shuffle

import requests
from django.conf import settings
from django.contrib.auth.hashers import check_password
from django.core.files.base import ContentFile
from django.core.mail import send_mail
from django.db.models import F, Q
from django.http import JsonResponse, HttpResponse
from django.shortcuts import get_object_or_404, render
from rest_framework import filters, generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.exceptions import NotFound, ValidationError
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from django.views.decorators.csrf import csrf_exempt
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import *
from .pagination import *
from .police_stations import CITY_AREAS
from .serializers import *
from .view_modules.auth_token_views import (
    exchange_web_login_token,
    generate_web_login_token,
    login_as_view,
)
from .view_modules.public_content_views import (
    getAdminNotice,
    getAuthenticationBanner,
    getLogo,
    get_eshop_logo,
)

# Create your views here.


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


@api_view(["POST"])
@permission_classes([AllowAny])
@csrf_exempt
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

        # Send welcome email to user + admin notification (async, non-blocking)
        try:
            from .email_service import send_welcome_email, notify_admin_new_registration
            if new_user.email:
                send_welcome_email(new_user)
            notify_admin_new_registration(new_user)
        except Exception as e:
            print(f"Email notification error (non-blocking): {e}")

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

    if user.kyc:
        protected_fields = {
            "first_name": user.first_name or "",
            "last_name": user.last_name or "",
            "address": user.address or "",
            "state": user.state or "",
            "city": user.city or "",
            "upazila": user.upazila or "",
            "zip": user.zip or "",
        }
        attempted_locked_changes = []
        for field_name, current_value in protected_fields.items():
            if field_name not in data:
                continue
            incoming_value = data.get(field_name)
            normalized_incoming = "" if incoming_value is None else str(incoming_value).strip()
            if normalized_incoming != str(current_value).strip():
                attempted_locked_changes.append(field_name)

        if attempted_locked_changes:
            return Response(
                {
                    "message": "Name and address details cannot be changed after KYC verification.",
                    "locked_fields": attempted_locked_changes,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

    if "image" in data:
        image_value = data.get("image")
        if image_value in [None, ""]:
            if user.image:
                user.image.delete(save=False)
            user.image = None
            data["image"] = None
        else:
            try:
                data["image"] = base64ToFile(image_value)
            except Exception as e:
                return Response(
                    {"message": "Failed to process image", "error": str(e)},
                    status=status.HTTP_400_BAD_REQUEST,
                )
    if "store_banner" in data:
        banner_value = data.get("store_banner")
        if banner_value in [None, ""]:
            if user.store_banner:
                user.store_banner.delete(save=False)
            user.store_banner = None
            data["store_banner"] = None
        else:
            try:
                data["store_banner"] = base64ToFile(banner_value)
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


@api_view(["PATCH"])
@permission_classes([IsAuthenticated])
def update_profile_picture(request):
    """Update user profile picture"""
    try:
        user = request.user
        
        if 'image' not in request.FILES:
            return Response(
                {"message": "No image file provided"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update user image
        user.image = request.FILES['image']
        user.save()
        
        # Return updated user data
        serializer = UserSerializer(user)
        return Response(
            {"message": "Profile picture updated successfully", "data": serializer.data},
            status=status.HTTP_200_OK
        )
    except Exception as e:
        print(f"Error updating profile picture: {str(e)}")
        return Response(
            {"message": "Failed to update profile picture", "error": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


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
        elif str(lookup_value).replace("+", "").replace("-", "").replace(" ", "").isdigit():
            # Phone lookup - check if it's a phone number (with or without +, -, spaces)
            # This handles formats like: +8801711111004, 8801711111004, +880-171-111-1004, etc.
            filter_kwargs = {"phone": lookup_value}
            lookup_type = "phone"
        else:
            # ID lookup (UUID or integer)
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
    pagination_class = None  # Disable pagination for Vue compatibility


class GetMicroGigs(generics.ListCreateAPIView):
    serializer_class = MicroGigPostSerializer
    permission_classes = [AllowAny]
    pagination_class = None  # Disable pagination for Vue compatibility

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

            # Check if this is an appeal (rejected -> pending)
            if micro_gig_post.gig_status == 'rejected' and request.data.get('gig_status') == 'pending':
                micro_gig_post.appeal_count += 1

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
    if not request.user.kyc and not request.user.is_superuser:
        message = (
            "Your KYC verification is pending. Please wait for approval before posting."
            if request.user.kyc_pending
            else "KYC verification is needed to post."
        )
        return Response(
            {
                "error": message,
                "message": message,
                "code": "kyc_verification_required",
            },
            status=status.HTTP_403_FORBIDDEN,
        )

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


class GetFoodZonePosts(generics.ListAPIView):
    """
    API endpoint to fetch classified posts from categories marked as Food Zone.
    Returns posts from all categories where is_food_zone=True.
    """
    serializer_class = ClassifiedPostSerializer
    pagination_class = ClassifiedPostPagination
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = (
            ClassifiedCategoryPost.objects.filter(
                service_status="approved",
                category__is_food_zone=True  # Only posts from food zone categories
            )
            .select_related("category")
            .prefetch_related("medias")
            .order_by("-created_at")
        )

        # Optional location filters
        country = self.request.query_params.get("country")
        state = self.request.query_params.get("state")
        city = self.request.query_params.get("city")
        upazila = self.request.query_params.get("upazila")

        if country:
            queryset = queryset.filter(country__iexact=country)
        if state:
            queryset = queryset.filter(state__iexact=state)
        if city:
            queryset = queryset.filter(city__iexact=city)
        if upazila:
            queryset = queryset.filter(upazila__iexact=upazila)

        # Support search
        search_query = self.request.query_params.get("search")
        if search_query:
            queryset = queryset.filter(
                Q(title__icontains=search_query) | Q(instructions__icontains=search_query)
            )

        # Filter by specific category within food zone
        category_id = self.request.query_params.get("category")
        if category_id:
            queryset = queryset.filter(category__id=category_id)

        return queryset


class GetFoodZoneCategories(generics.ListAPIView):
    """
    API endpoint to fetch all categories marked as Food Zone.
    """
    serializer_class = ClassifiedServicesSerializer
    permission_classes = [AllowAny]
    pagination_class = None

    def get_queryset(self):
        return ClassifiedCategory.objects.filter(is_food_zone=True).order_by("title")


class GetClassifiedPosts(generics.ListAPIView):
    serializer_class = ClassifiedPostSerializer
    pagination_class = ClassifiedPostPagination
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = (
            ClassifiedCategoryPost.objects.filter(service_status="approved")
            .select_related("category")
            .order_by("-created_at")
        )

        # Support both 'search' and 'title' parameters for backward compatibility
        search_query = self.request.query_params.get("search") or self.request.query_params.get("title")
        
        # Filter by category if provided
        category_id = self.request.query_params.get("category")
        if category_id:
            queryset = queryset.filter(category__id=category_id)

        # Filter by user if provided
        user_id = self.request.query_params.get("user")
        if user_id:
            queryset = queryset.filter(user__id=user_id)

        # Apply search filter
        if search_query:
            queryset = queryset.filter(
                Q(title__icontains=search_query) | Q(instructions__icontains=search_query)
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
        exclude_state = self.request.GET.get("exclude_state")
        exclude_city = self.request.GET.get("exclude_city")
        exclude_upazila = self.request.GET.get("exclude_upazila")

        # Filter based on the query parameters
        filters = Q(service_status="approved", active_service=True)
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
        if exclude_state:
            posts = posts.exclude(state__iexact=exclude_state)
        if exclude_city:
            posts = posts.exclude(city__iexact=exclude_city)
        if exclude_upazila:
            posts = posts.exclude(upazila__iexact=exclude_upazila)
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
        ClassifiedCategoryPost.objects.filter(pk=post.pk).update(
            views_count=F("views_count") + 1
        )
        post.refresh_from_db(fields=["views_count"])
        serializer = ClassifiedPostSerializer(post)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except ClassifiedCategoryPost.DoesNotExist:
        # Fallback to ID in case slug is not found (for backwards compatibility)
        try:
            post = ClassifiedCategoryPost.objects.get(id=slug)
            ClassifiedCategoryPost.objects.filter(pk=post.pk).update(
                views_count=F("views_count") + 1
            )
            post.refresh_from_db(fields=["views_count"])
            serializer = ClassifiedPostSerializer(post)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except ClassifiedCategoryPost.DoesNotExist:
            return Response(
                {"error": "Post not found"}, status=status.HTTP_404_NOT_FOUND
            )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def report_classified_post(request, slug):
    try:
        post = ClassifiedCategoryPost.objects.get(slug=slug)
    except ClassifiedCategoryPost.DoesNotExist:
        try:
            post = ClassifiedCategoryPost.objects.get(id=slug)
        except ClassifiedCategoryPost.DoesNotExist:
            return Response(
                {"error": "Post not found"}, status=status.HTTP_404_NOT_FOUND
            )

    reason = (request.data.get("reason") or "").strip()
    details = (request.data.get("details") or request.data.get("description") or "").strip()
    valid_reasons = [
        choice[0] for choice in ClassifiedCategoryPostReport.REASON_CHOICES
    ]

    if reason not in valid_reasons:
        return Response(
            {"error": "Invalid report reason"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    report, created = ClassifiedCategoryPostReport.objects.get_or_create(
        post=post,
        reported_by=request.user,
        defaults={
            "reason": reason,
            "details": details or None,
        },
    )

    if not created:
        return Response(
            {"message": "You have already reported this service."},
            status=status.HTTP_200_OK,
        )

    return Response(
        {
            "message": "Report submitted successfully. We will review this service.",
            "report_id": str(report.id),
        },
        status=status.HTTP_201_CREATED,
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
    try:
        gig = MicroGigPost.objects.get(slug=gid)
        serializer = MicroGigPostDetailsSerializer(gig)
        data = serializer.data
        
        # Check if user has already submitted this gig
        if request.user.is_authenticated:
            has_submitted = MicroGigPostTask.objects.filter(
                user=request.user, 
                gig_id=gig.id
            ).exists()
            data['user_has_submitted'] = has_submitted
        else:
            data['user_has_submitted'] = False
            
        return Response(data, status=status.HTTP_200_OK)
    except MicroGigPost.DoesNotExist:
        return Response(
            {"error": f"Gig with slug '{gid}' not found"}, 
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {"error": f"Error retrieving gig: {str(e)}"}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


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
    from .pagination import StandardResultsSetPagination
    
    # Get filter parameter (pending, approved, all)
    filter_type = request.query_params.get('filter', 'all')
    
    # Base queryset
    queryset = MicroGigPostTask.objects.filter(user=request.user)
    
    # Apply filter
    if filter_type == 'pending':
        queryset = queryset.filter(approved=False, rejected=False)
    elif filter_type == 'approved':
        queryset = queryset.filter(approved=True)
    elif filter_type == 'rejected':
        queryset = queryset.filter(rejected=True)
    # 'all' returns everything
    
    # Order by created_at descending
    queryset = queryset.order_by("-created_at")
    
    # Apply pagination
    paginator = StandardResultsSetPagination()
    paginator.page_size = 15  # 15 items per page
    paginated_queryset = paginator.paginate_queryset(queryset, request)
    
    serializer = GetMicroGigPostTaskSerializer(paginated_queryset, many=True)
    
    return paginator.get_paginated_response(serializer.data)


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
    """
    Handle balance operations: deposit, withdraw, transfer
    """
    data = request.data.copy()
    data["user"] = request.user.id
    transaction_type = data.get("transaction_type", "").lower()
    
    # Validate and parse amount
    try:
        data["payable_amount"] = Decimal(str(data.get("payable_amount", 0))).quantize(Decimal("0.01"))
    except (ValueError, TypeError, InvalidOperation):
        return Response(
            {"error": "Invalid amount format"},
            status=status.HTTP_400_BAD_REQUEST,
        )
    
    amount = data["payable_amount"]
    
    # === TRANSFER VALIDATION ===
    if transaction_type == "transfer":
        # 1. Check contact field
        contact = data.get("contact", "").strip()
        if not contact:
            return Response(
                {"error": "Contact (user ID, email or phone) is required for transfer"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        # 2. Check minimum transfer amount
        if amount < Decimal("50.00"):
            return Response(
                {"error": "Minimum transfer amount is ৳50.00"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        # 3. Check maximum transfer amount
        if amount > Decimal("25000.00"):
            return Response(
                {"error": "Maximum single transfer limit is ৳25,000.00"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        # 4. Check sender balance
        if request.user.balance < amount:
            return Response(
                {"error": "Insufficient balance"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        # 5. Check self-transfer
        if contact == str(request.user.id) or contact == request.user.email or contact == request.user.phone:
            return Response(
                {"error": "You cannot transfer money to yourself"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        # 6. Find recipient user (by ID, email, or phone)
        try:
            # Try to find user by ID, email, or phone
            # Build query dynamically to handle UUID validation
            query = Q(email=contact) | Q(phone=contact)
            
            # Try to parse as UUID for ID lookup
            try:
                import uuid
                uuid_contact = uuid.UUID(contact)
                query |= Q(id=uuid_contact)
            except (ValueError, AttributeError):
                # Not a valid UUID, skip ID lookup
                pass
            
            to_user = User.objects.get(query)
            
            print(f'✅ Found recipient user: {to_user.email} (ID: {to_user.id})')
            
        except User.DoesNotExist:
            return Response(
                {"error": f"Recipient user not found with contact: {contact}"},
                status=status.HTTP_404_NOT_FOUND,
            )
        except User.MultipleObjectsReturned:
            return Response(
                {"error": "Multiple users found with this contact"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        # Remove contact from data (not a model field)
        del data["contact"]
        
        # Set payment method for transfer
        data["payment_method"] = "p2p"
    
    # === DEPOSIT VALIDATION ===
    elif transaction_type == "deposit":
        if amount < Decimal("100.00"):
            return Response(
                {"error": "Minimum deposit amount is ৳100.00"},
                status=status.HTTP_400_BAD_REQUEST,
            )
    
    # === WITHDRAW VALIDATION ===
    elif transaction_type == "withdraw":
        if amount < Decimal("200.00"):
            return Response(
                {"error": "Minimum withdrawal amount is ৳200.00"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        # Check balance
        if request.user.balance < amount:
            return Response(
                {"error": "Insufficient balance"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        # Map 'selected' to 'payment_method'
        if "selected" in data:
            data["payment_method"] = data["selected"]
            del data["selected"]
        
        # Map 'payment_number' to 'card_number'
        if "payment_number" in data:
            data["card_number"] = data["payment_number"]
    
    # Check duplicate merchant invoice
    if "merchant_invoice_no" in data and data["merchant_invoice_no"]:
        if Balance.objects.filter(merchant_invoice_no=data["merchant_invoice_no"]).exists():
            return Response(
                {"error": "Transaction with this invoice number already exists"},
                status=status.HTTP_400_BAD_REQUEST,
            )
    
    # Serialize and save
    serializer = BalanceSerializer(data=data)
    
    if serializer.is_valid():
        # Create transaction
        transaction = serializer.save(user=request.user)
        
        # Set recipient for transfer
        if transaction_type == "transfer" and 'to_user' in locals():
            transaction.to_user = to_user
            transaction.save()  # This triggers the Balance.save() method which handles the transfer
        
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
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
    pagination_class = None  # Disable pagination for Vue compatibility


class GetTargetNetwork(generics.ListAPIView):
    queryset = TargetNetwork.objects.all()
    serializer_class = TargetNetworkSerializer
    permission_classes = [AllowAny]
    pagination_class = None  # Disable pagination for Vue compatibility


class GetTargetDevice(generics.ListAPIView):
    queryset = TargetDevice.objects.all()
    serializer_class = TargetDeviceSerializer
    permission_classes = [AllowAny]
    pagination_class = None  # Disable pagination for Vue compatibility


class GetTargetCountry(generics.ListAPIView):
    queryset = TargetCountry.objects.all()
    serializer_class = TargetCountrySerializer
    permission_classes = [AllowAny]
    pagination_class = None  # Disable pagination for Vue compatibility


class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

    def dispatch(self, *args, **kwargs):
        return super().dispatch(*args, **kwargs)

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
            validated = serializer.validated_data

            # Send login notification email asynchronously (non-blocking)
            try:
                import threading
                from .email_service import send_login_notification_email

                user_email = (validated.get("user") or {}).get("email") or ""
                if user_email:
                    logged_in_user = User.objects.filter(email=user_email).first()
                    if logged_in_user:
                        ip = (
                            request.META.get("HTTP_X_FORWARDED_FOR", "").split(",")[0].strip()
                            or request.META.get("REMOTE_ADDR", "")
                        )
                        ua = request.META.get("HTTP_USER_AGENT", "")
                        t = threading.Thread(
                            target=send_login_notification_email,
                            args=(logged_in_user, ip, ua),
                            daemon=True,
                        )
                        t.start()
            except Exception as email_err:
                print(f"Login email notification error (non-blocking): {email_err}")

            return Response(validated, status=status.HTTP_200_OK)
        except ValidationError:
            error_message = serializer.errors.get(
                "non_field_errors", ["Invalid credentials"]
            )[0]
            return Response(
                {"error": error_message}, status=status.HTTP_401_UNAUTHORIZED
            )
        except Exception as exc:
            return Response(
                {"error": str(exc) or "Login failed due to a server error"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class TokenValidationView(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    def get(self, request):
        user = request.user

        # Generate tokens using Simple JWT
        refresh = RefreshToken.for_user(user)

        # Pass context to serializer for absolute URL construction
        user_data = UserSerializerGet(user, context={'request': request}).data
        # Prepare the data to be returned
        data = {
            "refresh": str(refresh),
            "access": str(refresh.access_token),
            "user": user_data,
        }

        return Response(data)


@api_view(["GET"])
@permission_classes([AllowAny])
def email_unsubscribe(request):
    """Handle email unsubscribe via signed token link."""
    from django.core import signing
    from django.http import HttpResponse

    token = request.GET.get("token", "")
    if not token:
        return HttpResponse(
            "<html><body style='font-family:sans-serif;text-align:center;padding:60px;'>"
            "<h2>Invalid unsubscribe link.</h2></body></html>",
            content_type="text/html", status=400
        )
    try:
        email = signing.loads(token, salt="email-unsub", max_age=86400 * 90)
        user = User.objects.filter(email=email).first()
        if user:
            user.email_notifications = False
            user.save(update_fields=["email_notifications"])
        return HttpResponse(
            "<html><body style='font-family:-apple-system,sans-serif;text-align:center;padding:80px 20px;'>"
            "<div style='max-width:420px;margin:0 auto;'>"
            "<div style='font-size:48px;margin-bottom:20px;'>&#10003;</div>"
            "<h2 style='color:#0f172a;margin:0 0 10px;'>Unsubscribed</h2>"
            "<p style='color:#64748b;font-size:15px;margin:0;'>You have been unsubscribed from AdsyClub email notifications.</p>"
            "</div></body></html>",
            content_type="text/html"
        )
    except signing.BadSignature:
        return HttpResponse(
            "<html><body style='font-family:sans-serif;text-align:center;padding:60px;'>"
            "<h2>This unsubscribe link is invalid or has expired.</h2></body></html>",
            content_type="text/html", status=400
        )


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


def _send_smsinbd_message(phone, message):
    url = "http://api.smsinbd.com/sms-api/sendsms"
    payload = {
        "api_token": settings.API_SMS,
        "senderid": settings.SMS_SENDER_ID,
        "contact_number": phone,
        "message": message,
    }

    response = requests.get(url, params=payload, timeout=15)
    response_text = response.text.strip()
    response_data = None

    try:
        response_data = response.json()
    except json.JSONDecodeError:
        response_data = None

    if not 200 <= response.status_code < 300:
        return False, f"SMS service returned HTTP {response.status_code}"

    if isinstance(response_data, dict):
        provider_status = str(response_data.get("status", "")).lower()
        if provider_status in {"success", "sent", "submitted"}:
            return True, response_data.get("message", "SMS sent")

        provider_message = response_data.get("message") or response_text
        return False, provider_message or "SMS provider rejected the request"

    success_words = ("success", "sent", "submitted", "accepted")
    if any(word in response_text.lower() for word in success_words):
        return True, response_text

    return False, response_text or "SMS provider rejected the request"


@permission_classes([IsAuthenticated])
@api_view(["POST", "GET"])
def smsSend(request):
    phone = request.GET.get("phone")
    message = "Welcome to AdsyClub.com! You can now connect people enjoy services around you and earn money by completing tasks. Thank you!"

    try:
        sent, provider_message = _send_smsinbd_message(phone, message)
        if sent:
            return Response(
                {"message": "SMS sent successfully"},
                status=status.HTTP_200_OK,
            )
        return Response(
            {"error": f"SMS delivery failed: {provider_message}"},
            status=status.HTTP_400_BAD_REQUEST,
        )
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

    if method == "phone":
        message = f"Your AdsyClub password reset OTP is: {otp}. Valid for 10 minutes. Do not share this code."

        try:
            sent, provider_message = _send_smsinbd_message(phone, message)
            if sent:
                user.otp = otp
                user.save()

                from django.core.cache import cache

                cache.delete(f"otp_attempts_{phone}")
                return Response(
                    {
                        "message": "OTP sent successfully to your phone number",
                        "method": "phone",
                        "masked_phone": phone[:-4] + "****",
                    },
                    status=status.HTTP_200_OK,
                )

            return Response(
                {
                    "error": f"SMS delivery failed: {provider_message}. Please try again or contact support."
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
def delete_account(request):
    """
    Permanently delete the authenticated user's account and all associated data.
    Requires password confirmation for security.
    """
    user = request.user
    password = request.data.get("password")

    if not password:
        return Response(
            {"error": "Password confirmation is required to delete your account"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if not check_password(password, user.password):
        return Response(
            {"error": "Incorrect password"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Delete the user account (cascades to related data via Django's on_delete)
    user.delete()

    return Response(
        {"message": "Account deleted successfully"}, status=status.HTTP_200_OK
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
            try:
                from .email_service import send_password_reset_email
                send_password_reset_email(user, otp)
            except Exception as e:
                print(f"Email send error: {e}")
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
        """Return transfers AND ride earnings received by the current user."""
        from django.db.models import Q
        return (
            Balance.objects.filter(
                Q(to_user=self.request.user, completed=True,
                  transaction_type__in=["transfer", "ride_payment", "ride_due_settle"])
            )
            .select_related("user")
            .order_by("-updated_at")
        )


# product


# Product List and Create
class ProductListCreateView(generics.ListCreateAPIView):
    queryset = Product.objects.all().order_by("-created_at")
    serializer_class = ProductSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description', 'short_description', 'keywords', 'slug']
    ordering_fields = ['created_at', 'updated_at', 'regular_price', 'views', 'order_count']
    ordering = ['-created_at']

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


class ProductByIdView(generics.RetrieveUpdateDestroyAPIView):
    """Product detail view that uses ID instead of slug for mobile app"""
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    lookup_field = "id"

    def get_permissions(self):
        if self.request.method in ["GET", "HEAD", "OPTIONS"]:
            return [AllowAny()]
        return [IsAuthenticated()]

    def get_queryset(self):
        """Allow public reads but restrict mutations to the owner/admin scope."""
        if self.request.method in ["GET", "HEAD", "OPTIONS"]:
            return Product.objects.all()
        return Product.objects.filter(owner=self.request.user)

    def update(self, request, *args, **kwargs):
        try:
            partial = kwargs.pop("partial", True)  # Allow partial updates
            instance = self.get_object()

            # Update the main product data
            serializer = self.get_serializer(
                instance, data=request.data, partial=partial
            )
            serializer.is_valid(raise_exception=True)
            self.perform_update(serializer)

            return Response(serializer.data)

        except Exception as e:
            print(f"Update error: {str(e)}")
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

    def perform_update(self, serializer):
        serializer.save()

    def perform_destroy(self, instance):
        """Only allow users to delete their own products"""
        if self.request.user == instance.owner or self.request.user.is_staff:
            instance.delete()
        else:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You don't have permission to delete this product.")


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
        queryset = Product.objects.filter(is_active=True).prefetch_related(
            "category", "image"
        )

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

        normalized_category = category.strip() if isinstance(category, str) else category
        normalized_category_slug = category_slug.strip() if isinstance(category_slug, str) else category_slug

        if normalized_category_slug and normalized_category_slug != "undefined":
            queryset = queryset.filter(category__slug=normalized_category_slug)
        elif normalized_category and normalized_category != "undefined":
            try:
                category_uuid = uuid.UUID(str(normalized_category))
                queryset = queryset.filter(category__id=category_uuid)
            except (ValueError, AttributeError, TypeError):
                queryset = queryset.filter(category__slug=normalized_category)

        queryset = queryset.distinct()

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

        store_username = (
            self.request.query_params.get("store_username")
            or self.request.query_params.get("owner__store_username")
        )
        if isinstance(store_username, str) and store_username.strip():
            queryset = queryset.filter(owner__store_username=store_username.strip())

        owner_username = (
            self.request.query_params.get("owner_username")
            or self.request.query_params.get("owner__username")
        )
        if isinstance(owner_username, str) and owner_username.strip():
            queryset = queryset.filter(owner__username=owner_username.strip())

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
            return Product.objects.filter(
                id__in=selected_product_ids
            ).prefetch_related("category", "image").order_by(preserved_order)
        else:
            return Product.objects.none()


class StoreDetailsView(generics.RetrieveUpdateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [AllowAny]
    lookup_field = "store_username"

    def get_object(self):
        store_identity = self.kwargs.get(self.lookup_field)
        if not store_identity:
            raise Http404

        instance = (
            self.get_queryset()
            .filter(Q(store_username=store_identity) | Q(username=store_identity))
            .first()
        )
        if instance is None:
            raise Http404
        return instance

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
        store_identity = self.kwargs.get("store_username")
        if not store_identity:
            return Product.objects.none()

        store_owner = User.objects.filter(
            Q(store_username=store_identity) | Q(username=store_identity)
        ).first()
        if not store_owner:
            return Product.objects.none()

        return Product.objects.filter(owner=store_owner, is_active=True).order_by(
            "-created_at"
        )


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
        print(f"📦 SellerOrdersView - User: {self.request.user.email}")
        
        # Get IDs of products owned by the current user
        user_product_ids = Product.objects.filter(owner=self.request.user).values_list(
            "id", flat=True
        )
        print(f"📦 User has {len(user_product_ids)} products")

        # Find order items that contain these products
        order_ids = (
            OrderItem.objects.filter(product_id__in=user_product_ids)
            .values_list("order_id", flat=True)
            .distinct()
        )
        print(f"📦 Found {len(order_ids)} orders with user's products")

        # Get the base queryset
        queryset = Order.objects.filter(id__in=order_ids).order_by("-created_at")
        print(f"📦 Returning {queryset.count()} orders")

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


class SellerOrderUpdateView(generics.UpdateAPIView):
    """View for updating order status by sellers"""
    
    serializer_class = SellerOrderSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = "id"
    
    def get_queryset(self):
        """Only allow sellers to update orders containing their products"""
        user_product_ids = Product.objects.filter(owner=self.request.user).values_list("id", flat=True)
        order_ids = OrderItem.objects.filter(product_id__in=user_product_ids).values_list("order_id", flat=True).distinct()
        return Order.objects.filter(id__in=order_ids)
    
    def update(self, request, *args, **kwargs):
        try:
            instance = self.get_object()
            new_status = request.data.get('order_status')
            
            if new_status:
                instance.order_status = new_status
                instance.save()
                
                print(f"✅ Order {instance.order_number} status updated to {new_status} by {request.user.email}")
                
                return Response({
                    'success': True,
                    'message': f'Order status updated to {new_status}',
                    'data': SellerOrderSerializer(instance, context={'request': request}).data
                })
            else:
                return Response({
                    'success': False,
                    'message': 'order_status is required'
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            print(f"❌ Error updating order: {str(e)}")
            return Response({
                'success': False,
                'message': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)


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
    pagination_class = None  # Disable pagination for Vue compatibility


class ShopBannerImageListView(generics.ListAPIView):
    """
    View to retrieve all shop banners.
    """

    queryset = ShopBannerImage.objects.all()
    serializer_class = ShopBannerImageSerializer
    pagination_class = None  # Disable pagination for Vue compatibility


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


@api_view(["GET"])
def getBNLogo(request):
    """
    Get the most recent Business Network logo (single object like main logo)
    """
    try:
        bn_logo = BNLogo.objects.order_by("-created_at").first()
        if bn_logo:
            serializer = BNLogoSerializer(bn_logo)
            return Response(serializer.data)
        return Response({"image": None}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["GET"])
def getNewsLogo(request):
    """
    Get the most recent AdsyNews logo (single object like main logo)
    """
    try:
        news_logo = NewsLogo.objects.order_by("-created_at").first()
        if news_logo:
            serializer = NewsLogoSerializer(news_logo)
            return Response(serializer.data)
        return Response({"image": None}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


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
    pagination_class = None  # Disable pagination for Vue compatibility


class ProductSlotPackageListView(generics.ListAPIView):
    queryset = ProductSlotPackage.objects.all()
    serializer_class = ProductSlotPackageSerializer
    permission_classes = [AllowAny]
    pagination_class = None  # Disable pagination for Vue compatibility


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
                    "download_url": "",
                    "file_size_mb": None,
                    "version_name": "",
                    "version_code": 0,
                    "release_notes": "",
                    "message": "No app version configured",
                }
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

    queryset = AILink.objects.filter(is_active=True)
    serializer_class = AILinkSerializer
    permission_classes = [AllowAny]
    
    def get(self, request, *args, **kwargs):
        """Return the first active AI link configuration"""
        ai_link = AILink.objects.filter(is_active=True).first()
        if ai_link:
            serializer = self.get_serializer(ai_link)
            return Response(serializer.data)
        return Response({"error": "No active AI configuration found"}, status=404)


@api_view(["POST"])
@permission_classes([AllowAny])
def ai_business_finder(request):
    """
    AI-powered business finder using OpenAI API.
    Searches for businesses based on location and business type.
    """
    try:
        def _clean_str(v):
            if v is None:
                return None
            s = str(v).strip()
            if not s:
                return None
            low = s.lower()
            if low in {"null", "n/a", "na", "none", "unknown"}:
                return None
            return s

        def _tokenize_text(value: str):
            return {
                token
                for token in re.findall(r"[a-z0-9]+", (value or "").lower())
                if len(token) > 1
            }

        def _contains_placeholder_text(value: str) -> bool:
            low = (value or "").strip().lower()
            if not low:
                return True
            placeholder_phrases = {
                "business name",
                "company name",
                "shop name",
                "service provider",
                "sample business",
                "example business",
                "dummy business",
                "placeholder",
                "lorem ipsum",
                "brief description of the business",
                "description of the business",
                "to be updated",
                "coming soon",
            }
            return any(phrase in low for phrase in placeholder_phrases)

        def _is_generic_business_name(name: str) -> bool:
            low = name.strip().lower()
            if not low or _contains_placeholder_text(low):
                return True

            bt_tokens = _tokenize_text(business_type)
            loc_tokens = _tokenize_text(location_str)
            name_tokens = _tokenize_text(name)
            generic_tokens = {
                "bangladesh",
                "bd",
                "service",
                "services",
                "shop",
                "store",
                "mart",
                "center",
                "centre",
                "solution",
                "solutions",
                "agency",
                "traders",
                "enterprise",
                "enterprises",
                "business",
                "company",
                "co",
                "limited",
                "ltd",
                "house",
                "point",
                "hub",
                "world",
                "best",
                "top",
                "local",
                "trusted",
                "professional",
            }

            if bt_tokens and name_tokens and name_tokens.issubset(bt_tokens | loc_tokens | generic_tokens):
                return True

            return False

        def _is_generic_description(description: str) -> bool:
            low = description.strip().lower()
            if not low:
                return True
            if _contains_placeholder_text(low):
                return True

            generic_phrases = {
                "provides various services",
                "offers various services",
                "offers a wide range of services",
                "known for quality service",
                "serves the local area",
                "located in bangladesh",
                "contact for more details",
                "more information available on request",
            }
            return any(phrase in low for phrase in generic_phrases)

        def _is_generic_address(address: str) -> bool:
            low = address.strip().lower()
            if not low:
                return True
            if _contains_placeholder_text(low):
                return True

            normalized_locations = {
                (country or "").strip().lower(),
                (state or "").strip().lower(),
                (city or "").strip().lower(),
                (upazila or "").strip().lower(),
                (location_str or "").strip().lower(),
            }
            normalized_locations.discard("")
            if low in normalized_locations:
                return True

            address_tokens = _tokenize_text(address)
            loc_tokens = _tokenize_text(location_str)
            if address_tokens and address_tokens.issubset(loc_tokens | {"bangladesh", "road", "area", "city"}):
                return True

            return False

        def _is_valid_bd_phone(phone: str) -> bool:
            p = phone.strip()
            if not p:
                return False
            if "x" in p.lower():
                return False
            compact = re.sub(r"[\s\-()]", "", p)
            if "1234567" in compact or "12345678" in compact:
                return False
            mobile_intl = re.fullmatch(r"\+8801\d{9}", compact)
            mobile_local = re.fullmatch(r"01\d{9}", compact)
            landline_intl = re.fullmatch(r"\+880\d{1,2}\d{6,8}", compact)
            landline_dash = re.fullmatch(r"\+880\-?\d{1,2}\-?\d{6,8}", p)
            return bool(mobile_intl or mobile_local or landline_intl or landline_dash)

        def _is_valid_email(email: str) -> bool:
            e = email.strip()
            if not e:
                return False
            return bool(re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", e))

        def _is_likely_valid_website(url: str) -> bool:
            u = url.strip()
            if not u:
                return False
            if " " in u:
                return False
            low = u.lower()
            if "example.com" in low or "test.com" in low:
                return False
            if low.startswith("http://") or low.startswith("https://"):
                return "." in low
            return bool(re.fullmatch(r"[a-z0-9\-_.]+\.[a-z]{2,}.*", low))

        def _extract_email_domain(email: str):
            e = email.strip().lower()
            if "@" not in e:
                return None
            return e.split("@", 1)[1]

        def _extract_website_host(website: str):
            w = website.strip()
            if not w:
                return None
            if not (w.lower().startswith("http://") or w.lower().startswith("https://")):
                w = "https://" + w
            try:
                host = requests.utils.urlparse(w).hostname or ""
            except Exception:
                host = ""
            host = host.lower().strip()
            if host.startswith("www."):
                host = host[4:]
            return host or None

        def _is_website_consistent(email, website):
            if not email or not website:
                return True
            ed = _extract_email_domain(email)
            wh = _extract_website_host(website)
            if not ed or not wh:
                return False
            if ed.startswith("www."):
                ed = ed[4:]
            return wh == ed or wh.endswith("." + ed) or ed.endswith("." + wh)

        def _sanitize_businesses(businesses):
            cleaned = []
            seen_names = set()
            for b in businesses or []:
                if not isinstance(b, dict):
                    continue
                name = _clean_str(b.get("name"))
                if not name or _is_generic_business_name(name):
                    continue

                normalized_name = re.sub(r"\s+", " ", name.lower()).strip()
                if normalized_name in seen_names:
                    continue
                seen_names.add(normalized_name)

                item = {"name": name}

                description = _clean_str(b.get("description"))
                if description and not _is_generic_description(description):
                    item["description"] = description

                address = _clean_str(b.get("address"))
                if address and not _is_generic_address(address):
                    item["address"] = address

                phone = _clean_str(b.get("phone"))
                if phone and _is_valid_bd_phone(phone):
                    item["phone"] = phone

                email = _clean_str(b.get("email"))
                if email and _is_valid_email(email):
                    item["email"] = email

                website = _clean_str(b.get("website"))
                if website and _is_likely_valid_website(website):
                    item["website"] = website

                if not _is_website_consistent(item.get("email"), item.get("website")):
                    item.pop("website", None)

                if not any(item.get(field) for field in ("address", "phone", "email", "website")):
                    continue

                cleaned.append(item)

            phone_counts = {}
            website_counts = {}
            for item in cleaned:
                p = item.get("phone")
                if isinstance(p, str) and p.strip():
                    phone_counts[p.strip()] = phone_counts.get(p.strip(), 0) + 1
                w = item.get("website")
                if isinstance(w, str) and w.strip():
                    website_counts[w.strip()] = website_counts.get(w.strip(), 0) + 1

            for item in cleaned:
                p = item.get("phone")
                if isinstance(p, str) and phone_counts.get(p.strip(), 0) > 1:
                    item.pop("phone", None)
                w = item.get("website")
                if isinstance(w, str) and website_counts.get(w.strip(), 0) > 1:
                    item.pop("website", None)

            return cleaned

        # Get request data
        country = request.data.get('country', 'Bangladesh')
        state = request.data.get('state', '')
        city = request.data.get('city', '')
        upazila = request.data.get('upazila', '')
        business_type = request.data.get('business_type', '')
        
        if not business_type:
            return Response({"error": "business_type is required"}, status=400)
        
        # Get active AI configuration
        ai_config = AILink.objects.filter(is_active=True).first()
        if not ai_config:
            return Response({"error": "No active AI configuration found"}, status=404)
        
        # Build location string
        location_parts = [part for part in [upazila, city, state, country] if part and part not in ['All Bangladesh', 'All Cities', 'All Areas']]
        location_str = ', '.join(location_parts) if location_parts else country
        
        # If using Cloudflare worker (legacy)
        if ai_config.provider == 'cloudflare' and ai_config.link:
            try:
                cloudflare_url = f"{ai_config.link}&country={country}&city={city}&state={state}&business_type={business_type}&extra_command=search for fields: name,description,address,phone,email,website"
                cf_response = requests.get(cloudflare_url, timeout=30)
                if cf_response.status_code == 200:
                    data = cf_response.json()
                    if isinstance(data.get('data'), list):
                        return Response({"businesses": _sanitize_businesses(data['data'])})
                    elif isinstance(data.get('data', {}).get('businesses'), list):
                        return Response({"businesses": _sanitize_businesses(data['data']['businesses'])})
                    return Response({"businesses": []})
            except Exception as e:
                print(f"Cloudflare worker error: {e}")
                return Response({"error": "Failed to fetch from Cloudflare worker"}, status=500)
        
        # Using OpenAI
        if ai_config.provider == 'openai' and ai_config.api_key:
            try:
                openai_url = "https://api.openai.com/v1/chat/completions"
                headers = {
                    "Authorization": f"Bearer {ai_config.api_key}",
                    "Content-Type": "application/json"
                }
                
                prompt = f"""You are a helpful assistant that finds local businesses in Bangladesh. 
Find {business_type} businesses in {location_str}.

Return a JSON array of businesses with the following structure:
[
  {{
    "name": "Business Name",
    "description": "Brief description of the business",
    "address": "Full address with area, city",
    "phone": "Real Bangladesh phone number starting with +880 or 01XXX-XXXXXX format",
    "email": "Business email address",
    "website": "Website URL"
  }}
]

CRITICAL INSTRUCTIONS:
- Return ONLY the JSON array, no other text or markdown
- Include up to 5 real businesses that actually exist in that area
- For phone numbers: Use realistic Bangladesh mobile format like +8801712345678 or landline like +880-2-1234567. DO NOT use placeholder X characters.
- If you genuinely don't know a specific detail, use null instead of fake/placeholder data
- Do NOT invent business names, addresses, websites, phone numbers, or emails
- If a business cannot be supported by at least one real contact/detail field (address, phone, email, or website), omit it completely
- Never return generic example names like "Best {business_type}", "Local {business_type} Service", "Business Name", or similar placeholders
- If you are uncertain about all candidates, return an empty JSON array []
- Focus only on businesses you have high confidence about from prior knowledge
- Include real website URLs if you know them, otherwise use null"""

                payload = {
                    "model": ai_config.model or "gpt-3.5-turbo",
                    "messages": [
                        {"role": "system", "content": "You are a local business finder assistant. Always respond with valid JSON arrays only."},
                        {"role": "user", "content": prompt}
                    ],
                    "temperature": 0.0,
                    "max_tokens": 1500
                }
                
                openai_response = requests.post(openai_url, headers=headers, json=payload, timeout=60)
                
                if openai_response.status_code == 200:
                    result = openai_response.json()
                    content = result.get('choices', [{}])[0].get('message', {}).get('content', '[]')
                    
                    # Parse the JSON response
                    try:
                        # Clean up the response - remove markdown code blocks if present
                        content = content.strip()
                        if content.startswith('```json'):
                            content = content[7:]
                        if content.startswith('```'):
                            content = content[3:]
                        if content.endswith('```'):
                            content = content[:-3]
                        content = content.strip()
                        
                        businesses = json.loads(content)
                        if isinstance(businesses, list):
                            return Response({"businesses": _sanitize_businesses(businesses)})
                        return Response({"businesses": []})
                    except json.JSONDecodeError as e:
                        print(f"JSON parse error: {e}, content: {content}")
                        return Response({"businesses": [], "raw_response": content})
                else:
                    error_msg = openai_response.json().get('error', {}).get('message', 'Unknown error')
                    print(f"OpenAI API error: {openai_response.status_code} - {error_msg}")
                    return Response({"error": f"OpenAI API error: {error_msg}"}, status=openai_response.status_code)
                    
            except requests.exceptions.Timeout:
                return Response({"error": "Request timed out"}, status=504)
            except Exception as e:
                print(f"OpenAI error: {e}")
                return Response({"error": str(e)}, status=500)
        
        return Response({"error": "AI configuration is incomplete"}, status=400)
        
    except Exception as e:
        print(f"AI business finder error: {e}")
        return Response({"error": str(e)}, status=500)


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


# Digital Asset Links for Android App Links verification
def assetlinks_json(request):
    """
    Serve .well-known/assetlinks.json for Android App Links domain verification.
    Must return application/json content type.
    Returns different fingerprints based on domain:
      - adsyclub.com: both 98 and 9B fingerprints
      - www.adsyclub.com: only 9B fingerprint
    """
    host = request.get_host().split(':')[0].lower()

    if host == 'www.adsyclub.com':
        fingerprints = [
            "9A:57:C9:8C:75:97:87:F7:F6:E1:2C:1F:AD:AB:97:05:30:9D:DF:B4:3D:FC:3B:7D:9B:A9:74:F6:09:B2:E0:11"
        ]
    else:
        fingerprints = [
            "9A:57:C9:8C:75:97:87:F7:F6:E1:2C:1F:AD:AB:97:05:30:9D:DF:B4:3D:FC:3B:7D:98:A9:74:F6:09:B2:E0:11",
            "9A:57:C9:8C:75:97:87:F7:F6:E1:2C:1F:AD:AB:97:05:30:9D:DF:B4:3D:FC:3B:7D:9B:A9:74:F6:09:B2:E0:11"
        ]

    data = json.dumps([
        {
            "relation": ["delegate_permission/common.handle_all_urls"],
            "target": {
                "namespace": "android_app",
                "package_name": "com.oxius.app",
                "sha256_cert_fingerprints": fingerprints
            }
        }
    ])
    return HttpResponse(data, content_type='application/json')


def apple_app_site_association(request):
    """
    Serve apple-app-site-association for iOS Universal Links verification.
    """
    ios_team_id = getattr(settings, "IOS_APP_TEAM_ID", "").strip()
    details = []

    if ios_team_id:
        details.append(
            {
                "appID": f"{ios_team_id}.com.oxius.app",
                "paths": [
                    "*",
                ],
            }
        )

    data = json.dumps(
        {
            "applinks": {
                "apps": [],
                "details": details,
            }
        }
    )
    return HttpResponse(data, content_type="application/json")


# for frontend


def index(request, **args):
    """
    Handle frontend routing - serve built Nuxt.js frontend files
    """
    import os
    
    # Check if this is an API request
    if request.path.startswith("/api/"):
        return JsonResponse({"error": "Invalid API endpoint"}, status=404)

    # Try to serve the built Nuxt.js index.html
    frontend_index = os.path.join(settings.BASE_DIR, "frontend", "dist", "index.html")
    
    if os.path.exists(frontend_index):
        # Serve the built frontend
        with open(frontend_index, 'r', encoding='utf-8') as f:
            return HttpResponse(f.read(), content_type='text/html')
    
    # Fallback for development - show dev page only in DEBUG mode
    if settings.DEBUG:
        try:
            return render(request, "index.html")
        except:
            pass
    
    # Production fallback - redirect to frontend or show error
    return HttpResponse(
        """
        <!DOCTYPE html>
        <html>
        <head>
            <title>AdsyClub</title>
            <meta http-equiv="refresh" content="0;url=/">
        </head>
        <body>
            <p>Loading...</p>
        </body>
        </html>
        """,
        content_type='text/html'
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


@api_view(["GET"])
@permission_classes([AllowAny])
def get_translations(request, language_code):
    """
    API endpoint to get translations for a specific language.
    This reads from the frontend i18n config file and returns translations.
    """
    import os
    
    # Path to your i18n config file
    i18n_file_path = os.path.join(settings.BASE_DIR, 'frontend', 'i18n.config.ts')
    
    try:
        with open(i18n_file_path, 'r', encoding='utf-8') as file:
            content = file.read()
            
        # Extract the translations object from TypeScript file
        # This is a simple parser - you might want to use a more robust solution
        start_marker = f'{language_code}: {{'
        if start_marker not in content:
            return Response({'error': f'Language {language_code} not found'}, status=404)
            
        start_index = content.find(start_marker)
        if start_index == -1:
            return Response({'error': f'Language {language_code} not found'}, status=404)
            
        # Find the matching closing brace
        brace_count = 0
        start_pos = content.find('{', start_index)
        i = start_pos
        
        while i < len(content):
            if content[i] == '{':
                brace_count += 1
            elif content[i] == '}':
                brace_count -= 1
                if brace_count == 0:
                    break
            i += 1
        
        # Extract the language block
        lang_block = content[start_pos:i+1]
        
        # Parse the translations (simplified parser)
        translations = {}
        lines = lang_block.split('\n')
        
        for line in lines:
            line = line.strip()
            if ':' in line and not line.startswith('//'):
                # Extract key-value pairs
                if line.endswith(','):
                    line = line[:-1]
                
                parts = line.split(':', 1)
                if len(parts) == 2:
                    key = parts[0].strip().strip('"\'')
                    value = parts[1].strip().strip('",\'')
                    
                    # Handle multi-line values
                    if value.startswith('"') and not value.endswith('"'):
                        continue
                    
                    if key and value and not key.startswith('{') and not key.startswith('}'):
                        translations[key] = value.strip('"\'')
        
        return Response({
            'language': language_code,
            'translations': translations
        })
        
    except FileNotFoundError:
        return Response({'error': 'Translation file not found'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=500)


@api_view(["GET"])
@permission_classes([AllowAny])
def get_banners(request):
    """
    API endpoint to get banner images for the hero slider.
    """
    try:
        # You can customize this to fetch from your database or use static images
        banners = [
            {
                "id": 1,
                "image_url": f"{request.build_absolute_uri('/static/')}images/banner1.jpg",
                "title": "Welcome to AdsyClub",
                "subtitle": "Your Social Business Network",
                "link_type": "internal",
            },
            {
                "id": 2,
                "image_url": f"{request.build_absolute_uri('/static/')}images/banner2.jpg", 
                "title": "Earn Money Online",
                "subtitle": "Start your journey today",
                "link_type": "internal",
            },
            {
                "id": 3,
                "image_url": f"{request.build_absolute_uri('/static/')}images/banner3.jpg",
                "title": "E-Learning Platform", 
                "subtitle": "Learn new skills",
                "link_type": "internal",
            }
        ]
        
        return Response({
            'banners': banners,
            'count': len(banners)
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=500)


@api_view(["GET"])
@permission_classes([AllowAny])
def get_available_languages(request):
    """
    API endpoint to get list of available languages.
    """
    languages = [
        {
            'code': 'en',
            'name': 'English',
            'native_name': 'English',
            'flag': '🇺🇸'
        },
        {
            'code': 'bn', 
            'name': 'Bengali',
            'native_name': 'বাংলা',
            'flag': '🇧🇩'
        }
    ]
    
    return Response({
        'languages': languages,
        'default_language': 'en'
    })


# Search History Views
def _normalize_search_query(query):
    return ' '.join((query or '').strip().split())


def _dedupe_user_search_history(user, search_type='product', limit=10):
    if not user or not user.is_authenticated:
        return []

    keep_ids = []
    delete_ids = []
    seen_queries = set()

    searches = SearchHistory.objects.filter(
        user=user,
        search_type=search_type,
    ).order_by('-created_at')

    for item in searches:
        normalized_key = _normalize_search_query(item.query).casefold()
        if not normalized_key:
            delete_ids.append(item.id)
        elif normalized_key in seen_queries or len(keep_ids) >= limit:
            delete_ids.append(item.id)
        else:
            seen_queries.add(normalized_key)
            keep_ids.append(item.id)

    if delete_ids:
        SearchHistory.objects.filter(id__in=delete_ids).delete()

    return keep_ids


class SearchHistoryListView(generics.ListAPIView):
    """Get user's recent search history"""
    serializer_class = SearchHistorySerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_authenticated:
            keep_ids = _dedupe_user_search_history(user, 'product', limit=10)
            return SearchHistory.objects.filter(
                id__in=keep_ids,
                user=user,
                search_type='product',
            ).order_by('-created_at')

        # Search history is private per account. Anonymous requests must never
        # receive global history from other users.
        return SearchHistory.objects.none()


@api_view(['POST'])
@permission_classes([AllowAny])
def save_search_history(request):
    """Save a search query to history"""
    query = _normalize_search_query(request.data.get('query', ''))
    search_type = request.data.get('search_type', 'product')
    
    if not query:
        return Response({'error': 'Query is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    if not request.user.is_authenticated:
        return Response({'saved': False, 'message': 'Authentication required for search history'}, status=status.HTTP_200_OK)

    user = request.user

    # Keep one canonical row per user/query. Delete old duplicates first so the
    # newest submitted search moves to the top and reloads cannot resurrect it.
    SearchHistory.objects.filter(
        user=user,
        query__iexact=query,
        search_type=search_type,
    ).delete()
    
    # Create new search history
    search_history = SearchHistory.objects.create(
        user=user,
        query=query,
        search_type=search_type
    )
    
    _dedupe_user_search_history(user, search_type, limit=10)
    
    return Response(SearchHistorySerializer(search_history).data, status=status.HTTP_201_CREATED)


@api_view(['DELETE'])
@permission_classes([AllowAny])
def clear_search_history(request):
    """Clear all search history for the user"""
    user = request.user
    if user.is_authenticated:
        SearchHistory.objects.filter(user=user, search_type='product').delete()
        return Response({'message': 'Search history cleared'}, status=status.HTTP_200_OK)
    return Response({'message': 'No authenticated search history to clear'}, status=status.HTTP_200_OK)


@api_view(['DELETE'])
@permission_classes([AllowAny])
def delete_search_history_item(request):
    """Delete a single search history item by query string"""
    user = request.user
    if not user.is_authenticated:
        return Response({'deleted': 0}, status=status.HTTP_200_OK)
    query = _normalize_search_query(request.data.get('query') or request.query_params.get('query', ''))
    if not query:
        return Response({'error': 'query is required'}, status=status.HTTP_400_BAD_REQUEST)
    deleted, _ = SearchHistory.objects.filter(
        user=user, query__iexact=query, search_type='product'
    ).delete()
    return Response({'deleted': deleted}, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_fcm_token(request):
    """Save or update user's FCM token for push notifications"""
    from .models import FCMToken
    
    print(f'\n📱 FCM Token Registration Request')
    print(f'   User: {request.user.email}')
    print(f'   Request data: {request.data}')
    
    fcm_token = str(request.data.get('fcm_token') or '').strip()
    voip_token = str(request.data.get('voip_token') or '').strip()
    voip_environment = str(request.data.get('voip_environment') or '').strip()
    device_type = request.data.get('device_type', 'android')
    
    if not fcm_token and not voip_token:
        print(f'   ❌ No FCM token provided')
        return Response(
            {'error': 'FCM token or VoIP token is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    print(f'   Token: {fcm_token[:50]}...')
    print(f'   VoIP Token: {voip_token[:24]}...')
    print(f'   Device: {device_type}')
    
    try:
        defaults = {
            'is_active': True,
            'device_type': device_type
        }
        if voip_token:
            defaults['voip_token'] = voip_token
            defaults['voip_environment'] = voip_environment

        if fcm_token:
            token_obj, created = FCMToken.objects.update_or_create(
                user=request.user,
                token=fcm_token,
                defaults=defaults
            )
        else:
            synthetic_token = f"voip:{voip_token}"
            token_obj, created = FCMToken.objects.update_or_create(
                user=request.user,
                voip_token=voip_token,
                defaults={**defaults, 'token': synthetic_token}
            )
        
        action = 'created' if created else 'updated'
        print(f'   ✅ FCM token {action} successfully')
        
        return Response({
            'message': 'FCM token saved successfully',
            'created': created,
            'voip_saved': bool(voip_token),
        }, status=status.HTTP_200_OK)
    except Exception as e:
        print(f'   ❌ Error: {e}')
        import traceback
        traceback.print_exc()
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
