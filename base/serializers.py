from .models import Product, ProductCategory, ProductMedia
from rest_framework import serializers
from .models import *
from business_network.models import *
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.exceptions import ValidationError
from django.contrib.auth.hashers import make_password
from sale.models import SalePost
from cities_light.models import City, Region, Country


class UserSerializer(serializers.ModelSerializer):
    post_count = serializers.SerializerMethodField()
    follower_count = serializers.SerializerMethodField()
    follow_count = serializers.SerializerMethodField()
    sale_post_count = serializers.SerializerMethodField()
    rating = serializers.SerializerMethodField()

    class Meta:
        model = User
        # Exclude the password field for security
        exclude = ('groups', 'user_permissions')
        extra_kwargs = {
            'password': {'write_only': True},
            # 'username': {'read_only': True},
        }
        depth = 1

    def get_post_count(self, obj):
        return BusinessNetworkPost.objects.filter(author=obj).count()

    def get_follower_count(self, obj):
        return BusinessNetworkFollowerModel.objects.filter(following=obj).count()

    def get_follow_count(self, obj):
        return BusinessNetworkFollowerModel.objects.filter(follower=obj).count()

    def get_sale_post_count(self, obj):
        # Only count active sale posts, not pending or other statuses
        return SalePost.objects.filter(user=obj, status='active').count()

    def get_rating(self, obj):
        """Calculate the average rating for this store from reviews on their products"""
        from reviews.models import Review
        from django.db.models import Avg

        # Get all reviews for products owned by this store
        avg_rating = Review.objects.filter(
            product__owner=obj,
            is_approved=True
        ).aggregate(Avg('rating'))['rating__avg']

        return round(avg_rating, 1) if avg_rating else 0.0

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise ValidationError(
                {"error": "This email is already registered."})
        return value

    def create(self, validated_data):
        # Hash the password
        validated_data['password'] = make_password(validated_data['password'])
        return User.objects.create(**validated_data)

    def update(self, instance, validated_data):
        # Check if the password is being updated
        if 'password' in validated_data:
            instance.set_password(validated_data['password'])
            validated_data.pop('password', None)  # Remove from validated_data

        # Update other fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        instance.save()
        return instance

    def to_representation(self, instance):
        """Customize the serialized output."""
        representation = super().to_representation(instance)
        # Remove the password field from the output
        representation.pop('password', None)
        return representation


class NIDSerializer(serializers.ModelSerializer):
    class Meta:
        model = NID
        fields = '__all__'


class MicroGigPostTaskSerializer(serializers.ModelSerializer):
    gig = serializers.PrimaryKeyRelatedField(
        queryset=MicroGigPost.objects.all())
    user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())

    class Meta:
        model = MicroGigPostTask
        fields = '__all__'
        depth = 1


class MicroGigPostMediaSerializer(serializers.ModelSerializer):
    class Meta:
        model = MicroGigPostMedia
        fields = '__all__'
        depth = 1


class GetMicroGigPostTaskSerializer(serializers.ModelSerializer):
    user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())
    user_details = UserSerializer(source='user', read_only=True)

    class Meta:
        model = MicroGigPostTask
        fields = '__all__'
        depth = 1


class UserSerializerGet(serializers.ModelSerializer):
    micro_gig_worker = GetMicroGigPostTaskSerializer(many=True, read_only=True)

    class Meta:
        model = User
        # Exclude the password field for security
        exclude = ('groups', 'user_permissions', 'password')
        extra_kwargs = {
            'password': {'write_only': True},
            # 'username': {'read_only': True},
        }
        depth = 1


class ClassifiedServicesSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClassifiedCategory
        fields = '__all__'
        read_only_fields = ['slug']


class MicroGigCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = MicroGigCategory
        fields = '__all__'
        read_only_fields = ['slug']


class TargetNetworkSerializer(serializers.ModelSerializer):
    class Meta:
        model = TargetNetwork
        fields = '__all__'


class TargetDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = TargetDevice
        fields = '__all__'


class TargetCountrySerializer(serializers.ModelSerializer):
    class Meta:
        model = TargetCountry
        fields = '__all__'


class MicroGigPostSerializer(serializers.ModelSerializer):
    category = serializers.PrimaryKeyRelatedField(
        queryset=MicroGigCategory.objects.all())
    category_details = MicroGigCategorySerializer(
        source='category', read_only=True)
    user = UserSerializerGet(read_only=True)
    submitted_tasks = MicroGigPostTaskSerializer(
        source='microgigposttask_set',
        many=True,
        read_only=True
    )

    class Meta:
        model = MicroGigPost
        fields = '__all__'
        depth = 1
        read_only_fields = ['slug']


class MicroGigPostDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = MicroGigPost
        depth = 1
        exclude = ['user']
        read_only_fields = ['slug']


class BalanceSerializer(serializers.ModelSerializer):
    user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())
    user_details = UserSerializer(source='user', read_only=True)
    to_user = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(), required=False, allow_null=True)
    to_user_details = UserSerializer(source='to_user', read_only=True)

    class Meta:
        model = Balance
        fields = '__all__'


class ClassifiedPostSerializer(serializers.ModelSerializer):
    category = serializers.PrimaryKeyRelatedField(
        queryset=ClassifiedCategory.objects.all())
    category_details = ClassifiedServicesSerializer(
        source='category', read_only=True)
    user = UserSerializerGet(read_only=True)

    class Meta:
        model = ClassifiedCategoryPost
        fields = '__all__'
        depth = 1
        read_only_fields = ['slug']


class logoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Logo
        fields = '__all__'


class EshopLogoSerializer(serializers.ModelSerializer):
    class Meta:
        model = EshopLogo
        fields = '__all__'


class AuthenticationBannerSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuthenticationBanner
        fields = '__all__'


class AdminNoticeSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.name', read_only=True)

    class Meta:
        model = AdminNotice
        fields = ['id', 'title', 'message', 'notification_type', 'user', 'user_name',
                  'amount', 'reference_id', 'is_read', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']

    def to_representation(self, instance):
        representation = super().to_representation(instance)
        return representation


# class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
#     @classmethod
#     def get_tokens_for_user(user):
#         refresh = RefreshToken.for_user(user)

#         return {
#             'refresh': str(refresh),
#             'access': str(refresh.access_token),
#         }
#     def validate(self, attrs):
#         username_or_email_or_phone = attrs.get('username')
#         password = attrs.get('password')
#         print(username_or_email_or_phone)

#         # Find user by email, username, or phone number
#         try:
#             user = User.objects.get(email=username_or_email_or_phone)
#         except User.DoesNotExist:
#             try:
#                 user = User.objects.get(username=username_or_email_or_phone)
#             except User.DoesNotExist:
#                 try:
#                     user = User.objects.get(phone=username_or_email_or_phone)
#                 except User.DoesNotExist:
#                     user = None

#         if user and user.check_password(password):
#             if not user.is_active:
#                 raise serializers.ValidationError("User is inactive.")
#         else:
#             raise serializers.ValidationError("Invalid credentials.")

#         data = super().validate(attrs)

#         # Add user details to the response payload
#         data.update({
#             'user': {
#                 'id': user.id,
#                 'username': user.username,
#                 'email': user.email,
#             }
#         })
#         return data

class CustomTokenObtainPairSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    password = serializers.CharField(required=True)

    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')

        # Authenticate the user by email and password
        # user = authenticate(email=email, password=password)

        # if user is None:
        #     raise serializers.ValidationError('Invalid email or password.')

        # Get user model
        User = get_user_model()

        # Ensure email-based authentication
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            raise serializers.ValidationError('Invalid email or password.')

        # Check the password
        if not user.check_password(password):
            raise serializers.ValidationError('Invalid email or password.')

        # Generate tokens using Simple JWT
        refresh = RefreshToken.for_user(user)

        user_data = UserSerializer(user).data

        # If authentication is successful, get the tokens
        data = {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': user_data,

        }

        return data


class ReceivedTransferSerializer(serializers.ModelSerializer):
    sender_details = UserSerializer(source='user', read_only=True)

    class Meta:
        model = Balance
        fields = ['id', 'sender_details', 'amount', 'payable_amount',
                  'created_at', 'updated_at', 'payment_method', 'transaction_type']


class ProductMediaSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductMedia
        fields = '__all__'


class ProductCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductCategory
        fields = '__all__'
        read_only_fields = ['slug']

# Serializer for ProductBenefit model


class ProductBenefitSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductBenefit
        fields = '__all__'
        read_only_fields = ['slug']

# Serializer for ProductFAQ model


class ProductFAQSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductFAQ
        fields = '__all__'
        read_only_fields = ['slug']

# Serializer for ProductTrustBadge model


class ProductTrustBadgeSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductTrustBadge
        fields = '__all__'
        read_only_fields = ['slug']


class ProductSerializer(serializers.ModelSerializer):
    category_details = ProductCategorySerializer(
        source='category', many=True, read_only=True)
    image_details = ProductMediaSerializer(
        source='image', many=True, read_only=True)
    owner_details = UserSerializer(source='owner', read_only=True)
    faqs = ProductFAQSerializer(many=True, read_only=True)
    benefits = ProductBenefitSerializer(many=True, read_only=True)
    order_count = serializers.SerializerMethodField()
    total_items_ordered = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = '__all__'
        read_only_fields = ['slug']

    def get_order_count(self, obj):
        return obj.order_count

    def get_total_items_ordered(self, obj):
        return obj.total_items_ordered


class ProductMinSerializer(serializers.ModelSerializer):
    """Minimal product information for order items"""
    image = ProductMediaSerializer(many=True, read_only=True)

    class Meta:
        model = Product
        fields = ['id', 'name', 'sale_price', 'image']


class OrderItemSerializer(serializers.ModelSerializer):
    product_details = ProductMinSerializer(source='product', read_only=True)

    class Meta:
        model = OrderItem
        fields = ['id', 'order', 'product', 'product_details',
                  'quantity', 'price', 'created_at']

    def validate_quantity(self, value):
        if value <= 0:
            raise serializers.ValidationError(
                "Quantity must be greater than 0")
        return value


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    user_email = serializers.EmailField(source='user.email', read_only=True)
    user_name = serializers.CharField(source='user.name', read_only=True)

    class Meta:
        model = Order
        fields = '__all__'

    def validate_total(self, value):
        if value < 0:
            raise serializers.ValidationError(
                "Total amount cannot be negative")
        return value


class SellerOrderSerializer(serializers.ModelSerializer):
    items = serializers.SerializerMethodField()
    user = serializers.PrimaryKeyRelatedField(read_only=True)
    customer_details = UserSerializer(source='user', read_only=True)

    class Meta:
        model = Order
        fields = '__all__'

    def get_items(self, obj):
        # Get only the items with products owned by the current user
        user = self.context['request'].user
        user_product_ids = Product.objects.filter(
            owner=user).values_list('id', flat=True)

        # Filter order items by these products
        items = obj.items.filter(product_id__in=user_product_ids)
        return OrderItemSerializer(items, many=True).data


class CitySerializer(serializers.ModelSerializer):
    class Meta:
        model = City
        fields = '__all__'


class RegionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Region
        fields = '__all__'


class CountrySerializer(serializers.ModelSerializer):
    class Meta:
        model = Country
        fields = '__all__'


class FaqSerializer(serializers.ModelSerializer):
    class Meta:
        model = Faq
        fields = ('label', 'content')
        read_only_fields = ['slug']


class BannerImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = BannerImage
        fields = '__all__'


class ShopBannerImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ShopBannerImage
        fields = '__all__'


class BNLogoSerializer(serializers.ModelSerializer):
    class Meta:
        model = BNLogo
        fields = ['id', 'image', 'created_at', 'updated_at']


class NewsLogoSerializer(serializers.ModelSerializer):
    class Meta:
        model = NewsLogo
        fields = ['id', 'image', 'created_at', 'updated_at']


class DiamondTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = DiamondTransaction
        fields = '__all__'


class DiamondPackagesSerializer(serializers.ModelSerializer):
    class Meta:
        model = DiamondPackages
        fields = '__all__'


class ProductSlotPackageSerializer(serializers.ModelSerializer):
    discount_percentage = serializers.IntegerField(read_only=True)

    class Meta:
        model = ProductSlotPackage
        fields = '__all__'


class EshopBannerSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    mobile_image_url = serializers.SerializerMethodField()

    class Meta:
        model = EshopBanner
        fields = ['id', 'image', 'mobile_image', 'image_url', 'mobile_image_url',
                  'title', 'link', 'device_type', 'is_active', 'order', 'created_at']

    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None

    def get_mobile_image_url(self, obj):
        if obj.mobile_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.mobile_image.url)
            return obj.mobile_image.url
        return None


class MobileBannerSerializer(serializers.ModelSerializer):
    """Serializer specifically for mobile banners with optimized response"""
    image = serializers.SerializerMethodField()

    class Meta:
        model = EshopBanner
        fields = ['id', 'image', 'title', 'link', 'order']

    def get_image(self, obj):
        # Return mobile-optimized image if available, otherwise fallback to regular image
        image_field = obj.mobile_image if obj.mobile_image else obj.image
        if image_field:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(image_field.url)
            return image_field.url
        return None

# Android App Version Serializer


class AndroidAppVersionSerializer(serializers.ModelSerializer):
    class Meta:
        model = AndroidAppVersion
        fields = ['version_name', 'version_code', 'download_url', 'release_notes',
                  'min_android_version', 'file_size_mb', 'created_at']


class AILinkSerializer(serializers.ModelSerializer):
    class Meta:
        model = AILink
        fields = '__all__'
