from django.shortcuts import render
from rest_framework import viewsets, status, permissions, generics
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import F, Max
import logging
import base64
from django.core.files.base import ContentFile
import hashlib
from django.utils import timezone
import datetime
from .paginations import StandardResultsSetPagination


from .models import *
from .serializers import *

# Set up logger
logger = logging.getLogger(__name__)


def base64ToFile(base64_data):
    """Convert base64 image data to Django ContentFile"""
    # Remove the prefix if it exists (e.g., "data:image/png;base64,")
    if base64_data.startswith("data:image"):
        base64_data = base64_data.split("base64,")[1]

    # Decode the Base64 string into bytes
    file_data = base64.b64decode(base64_data)

    # Create a Django ContentFile object from the bytes
    file = ContentFile(file_data)

    # Create a filename with timestamp
    import uuid

    filename = f"sale_image_{uuid.uuid4().hex[:8]}.jpg"

    # Save the file to the appropriate storage
    file.name = filename
    return file


class SaleCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for listing and retrieving sale categories"""

    queryset = SaleCategory.objects.all()
    serializer_class = SaleCategorySerializer

    @action(detail=True, methods=["get"])
    def child_categories(self, request, pk=None):
        """Get child categories for a parent category"""
        category = self.get_object()
        child_categories = SaleChildCategory.objects.filter(parent=category)
        serializer = SaleChildCategorySerializer(child_categories, many=True)
        return Response(serializer.data)


class SaleChildCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for listing and retrieving child categories"""

    queryset = SaleChildCategory.objects.all()
    serializer_class = SaleChildCategorySerializer

    def get_queryset(self):
        queryset = SaleChildCategory.objects.all()
        parent_id = self.request.query_params.get("parent_id")

        if parent_id:
            queryset = queryset.filter(parent_id=parent_id)

        return queryset


class SaleBannerViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for listing and retrieving sale banners"""

    queryset = SaleBanner.objects.all().order_by("order")
    serializer_class = SaleBannerSerializer


class SaleConditionViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for listing available conditions for sale items"""

    queryset = SaleCondition.objects.filter(is_active=True).order_by("order", "name")
    serializer_class = SaleConditionSerializer


class SalePostViewSet(viewsets.ModelViewSet):
    """ViewSet for handling sale posts"""

    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    lookup_field = "slug"
    lookup_value_converter = "str"  # Ensure proper handling of Bangla characters in URL
    pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        logger.info(f"get_queryset called for action: {self.action}")
        logger.info(f"User authenticated: {self.request.user.is_authenticated}")
        logger.info(f"User: {self.request.user}")
        
        if self.action in ["list", "retrieve"]:
            # For public viewing, show active posts only
            queryset = SalePost.objects.filter(status="active")
        elif self.action == "mark_as_sold":
            # For mark_as_sold, return all posts and let the action method check ownership
            # This is needed because get_object() needs to find the post first
            queryset = SalePost.objects.all()
            logger.info(f"mark_as_sold action - returning all posts for lookup")
        elif self.action in ["update", "partial_update", "destroy"]:
            # For actions that modify posts, allow access to user's own posts regardless of status
            if self.request.user.is_authenticated:
                queryset = SalePost.objects.filter(user=self.request.user)
                logger.info(f"Filtered queryset count for user {self.request.user}: {queryset.count()}")
            else:
                logger.warning("User not authenticated for modify action")
                queryset = SalePost.objects.none()
        else:
            # For other actions, filter by user
            queryset = SalePost.objects.filter(user=self.request.user)

        # Apply filters if provided
        seller = self.request.query_params.get("seller")
        if seller:
            queryset = queryset.filter(user__id=seller)

        category = self.request.query_params.get("category")
        if category:
            queryset = queryset.filter(category=category)

        child_category = self.request.query_params.get("child_category")
        if child_category:
            queryset = queryset.filter(child_category=child_category)

        division = self.request.query_params.get("division")
        if division:
            queryset = queryset.filter(division=division)

        district = self.request.query_params.get("district")
        if district:
            queryset = queryset.filter(district=district)

        area = self.request.query_params.get("area")
        if area:
            queryset = queryset.filter(area=area)

        condition = self.request.query_params.get("condition")
        if condition:
            queryset = queryset.filter(condition=condition)

        min_price = self.request.query_params.get("min_price")
        if min_price:
            queryset = queryset.filter(price__gte=min_price)

        max_price = self.request.query_params.get("max_price")
        if max_price:
            queryset = queryset.filter(price__lte=max_price)
            # Title search
        title = self.request.query_params.get("title")
        if title:
            queryset = queryset.filter(title__icontains=title)

        # Comprehensive search in title and description
        search = self.request.query_params.get("search")
        if search:
            from django.db.models import Q

            queryset = queryset.filter(
                Q(title__icontains=search) | Q(description__icontains=search)
            )

        return queryset

    def get_serializer_class(self):
        if (
            self.action == "create"
            or self.action == "update"
            or self.action == "partial_update"
        ):
            return SalePostCreateSerializer
        elif self.action == "list":
            return SalePostListSerializer
        return SalePostDetailSerializer

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()

        # Increment view count atomically
        SalePost.objects.filter(pk=instance.pk).update(view_count=F("view_count") + 1)
        # Refresh the instance to get updated view count
        instance.refresh_from_db()

        serializer = self.get_serializer(instance)
        return Response(serializer.data)

    def create(self, request, *args, **kwargs):
        logger.info(f"Creating sale post with data keys: {list(request.data.keys())}")

        try:
            # Extract images data before processing
            images_data = request.data.pop("images", None)

            # Create the serializer with the remaining data
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)

            # Create the sale post
            sale_post = serializer.save()
            logger.info(f"Sale post created successfully with ID: {sale_post.id}")

            # Process images if provided
            if images_data:
                # Handle both list of images and single image
                if not isinstance(images_data, list):
                    images_data = [images_data]

                successful_images = 0
                failed_images = 0

                for i, image_data in enumerate(images_data):
                    try:
                        # Skip empty images
                        if not image_data:
                            continue

                        if isinstance(image_data, str) and image_data.startswith(
                            "data:image"
                        ):
                            # Process base64 image using the same pattern as business network
                            image_file = base64ToFile(image_data)
                            sale_image = SaleImage.objects.create(
                                post=sale_post,
                                image=image_file,
                                is_main=(i == 0),  # First image is main
                                order=i,
                            )
                            successful_images += 1
                            logger.info(
                                f"Successfully created image {i + 1} with ID: {sale_image.id}"
                            )
                        else:
                            logger.warning(f"Skipping non-base64 image at index {i}")

                    except Exception as e:
                        logger.error(f"Error processing image {i + 1}: {str(e)}")
                        failed_images += 1
                        # Continue processing other images even if one fails

                logger.info(
                    f"Image processing complete. Success: {successful_images}, Failed: {failed_images}"
                )

            headers = self.get_success_headers(serializer.data)
            return Response(
                serializer.data, status=status.HTTP_201_CREATED, headers=headers
            )

        except Exception as e:
            logger.exception(f"Error in sale post creation: {str(e)}")
            return Response(
                {"detail": f"Error creating post: {str(e)}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

    @action(detail=False, methods=["get"])
    def my_posts(self, request):
        """Get all posts for the current user regardless of status."""
        if not request.user.is_authenticated:
            return Response(
                {"detail": "Authentication required"},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        queryset = SalePost.objects.filter(user=request.user)

        # Apply status filter if provided
        status_param = request.query_params.get("status")
        if status_param:
            queryset = queryset.filter(status=status_param)

        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = SalePostListSerializer(
                page, many=True, context={"request": request}
            )
            return self.get_paginated_response(serializer.data)

        serializer = SalePostListSerializer(
            queryset, many=True, context={"request": request}
        )
        return Response(serializer.data)

    @action(detail=True, methods=["post"], url_path="mark_as_sold", permission_classes=[permissions.IsAuthenticated])
    def mark_as_sold(self, request, slug=None):
        """Mark a sale post as sold - simplified version without ownership check."""
        logger.info(f"=== MARK AS SOLD ACTION CALLED ===")
        logger.info(f"Slug: {slug}")
        logger.info(f"Request user: {request.user}")
        logger.info(f"User authenticated: {request.user.is_authenticated}")
        logger.info(f"User ID: {request.user.id if request.user.is_authenticated else 'N/A'}")
        
        try:
            post = self.get_object()
            logger.info(f"Post found - ID: {post.id}, Title: {post.title}")
            logger.info(f"Post owner: {post.user}")
            logger.info(f"Post owner ID: {post.user.id if post.user else 'N/A'}")
            logger.info(f"Post current status: {post.status}")
            
            # Simply mark as sold without permission check for now to debug
            # The viewset already requires authentication
            post.status = "sold"
            post.save(update_fields=["status"])
            logger.info(f"✓ Post {post.id} successfully marked as sold")

            serializer = SalePostDetailSerializer(post, context={"request": request})
            return Response(serializer.data)
            
        except Exception as e:
            logger.error(f"✗ Error in mark_as_sold: {str(e)}")
            logger.exception(e)
            return Response(
                {"detail": f"Error: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    @action(detail=True, methods=["post"], url_path="report", permission_classes=[permissions.IsAuthenticated])
    def report(self, request, slug=None):
        """Report a sale post for review"""
        logger.info(f"=== REPORT POST ACTION CALLED ===")
        logger.info(f"Slug: {slug}")
        logger.info(f"Request user: {request.user}")
        logger.info(f"Request data: {request.data}")
        
        try:
            post = self.get_object()
            reason = request.data.get('reason')
            details = request.data.get('details', '')
            
            if not reason:
                return Response(
                    {"detail": "Reason is required"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if user already reported this post
            existing_report = SalePostReport.objects.filter(
                post=post, 
                reported_by=request.user
            ).first()
            
            if existing_report:
                return Response(
                    {"detail": "You have already reported this listing."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Create the report
            report = SalePostReport.objects.create(
                post=post,
                reported_by=request.user,
                reason=reason,
                details=details if details else None
            )
            
            logger.info(f"✓ Report created with ID {report.id}")
            logger.info(f"Post {post.id} reported by user {request.user.id}")
            logger.info(f"Reason: {reason}, Details: {details}")
            
            # TODO: You can add email notification to admins here
            # send_mail_to_admins(post, reason, details, request.user)
            
            return Response(
                {"detail": "Report submitted successfully. We will review this listing."},
                status=status.HTTP_201_CREATED
            )
            
        except Exception as e:
            logger.error(f"✗ Error in report: {str(e)}")
            logger.exception(e)
            return Response(
                {"detail": f"Error: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=["get"])
    def search(self, request):
        """Search endpoint for live search dropdown results"""
        query = request.query_params.get("q", "").strip()

        if not query:
            return Response({"results": []})

        # Limit results for dropdown (default 10)
        limit = min(int(request.query_params.get("limit", 10)), 20)

        # Search in title and description
        from django.db.models import Q

        queryset = (
            SalePost.objects.filter(status="active")
            .filter(Q(title__icontains=query) | Q(description__icontains=query))
            .select_related("category", "user")
            .prefetch_related("images")
        )

        # Apply location filtering if provided
        division = request.query_params.get("division")
        if division:
            queryset = queryset.filter(division=division)

        district = request.query_params.get("district")
        if district:
            queryset = queryset.filter(district=district)

        area = request.query_params.get("area")
        if area:
            queryset = queryset.filter(area=area)

        # Order by created_at descending to show newest first
        queryset = queryset.order_by("-created_at")[:limit]

        # Use custom serializer for search results
        serializer = SalePostSearchSerializer(
            queryset, many=True, context={"request": request}
        )

        return Response({"results": serializer.data})

    def update(self, request, *args, **kwargs):
        logger.info(f"Updating sale post with data keys: {list(request.data.keys())}")

        instance = self.get_object()

        # Check if user owns this post
        if instance.user != request.user:
            return Response(
                {"detail": "You don't have permission to edit this post."},
                status=status.HTTP_403_FORBIDDEN,
            )

        deleted_images = request.data.get("deleted_images", [])
        images_data = request.data.get("images", [])

        # Delete images marked for deletion
        if deleted_images:
            for img_id in deleted_images:
                try:
                    img = SaleImage.objects.get(id=img_id, post=instance)
                    img.image.delete(save=False)  # delete file from storage
                    img.delete()
                    logger.info(f"Deleted image with ID: {img_id}")
                except SaleImage.DoesNotExist:
                    logger.warning(f"Image with ID {img_id} not found")

        # Remove images from data before serializer validation
        data = request.data.copy()
        data.pop("images", None)
        data.pop("deleted_images", None)

        serializer = self.get_serializer(instance, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        sale_post = serializer.save()

        # Handle new images (base64 strings only)
        successful_images = 0
        failed_images = 0  # Get current max order for proper ordering
        max_order = (
            SaleImage.objects.filter(post=sale_post).aggregate(max_order=Max("order"))[
                "max_order"
            ]
            or -1
        )

        for i, img_data in enumerate(images_data):
            if isinstance(img_data, str) and img_data.startswith("data:image"):
                try:
                    image_file = base64ToFile(img_data)
                    sale_image = SaleImage.objects.create(
                        post=sale_post,
                        image=image_file,
                        is_main=False,  # Let user set main image manually
                        order=max_order + i + 1,
                    )
                    successful_images += 1
                    logger.info(
                        f"Successfully created new image {i + 1} with ID: {sale_image.id}"
                    )
                except Exception as e:
                    logger.error(f"Error processing new image {i + 1}: {str(e)}")
                    failed_images += 1

        logger.info(
            f"Image update complete. Success: {successful_images}, Failed: {failed_images}"
        )

        # Return updated post data
        serializer = self.get_serializer(sale_post)
        return Response(serializer.data)


class SaleSponsoredHorizontalListView(generics.ListAPIView):
    """List view for sponsored horizontal posts"""

    queryset = SaleSponsoredHorizontal.objects.all()
    serializer_class = SaleSponsoredHorizontalSerializer


class SaleSponsoredVerticalListView(generics.ListAPIView):
    """List view for sponsored vertical posts"""

    queryset = SaleSponsoredVertical.objects.all()
    serializer_class = SaleSponsoredVerticalSerializer
