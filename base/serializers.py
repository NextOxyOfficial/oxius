from rest_framework import serializers
from .models import *
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.exceptions import ValidationError
from django.contrib.auth.hashers import make_password

from cities_light.models import City, Region, Country


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        # Exclude the password field for security
        exclude = ('groups', 'user_permissions')
        extra_kwargs = {
            'password': {'write_only': True},
            # 'username': {'read_only': True},
        }
        depth = 1

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
    gig = serializers.PrimaryKeyRelatedField(queryset=MicroGigPost.objects.all())
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
        exclude = ('groups', 'user_permissions','password')
        extra_kwargs = {
            'password': {'write_only': True},
            # 'username': {'read_only': True},
        }
        depth = 1

class ClassifiedServicesSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClassifiedCategory
        fields = '__all__'

class MicroGigCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = MicroGigCategory
        fields = '__all__'

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
    category = serializers.PrimaryKeyRelatedField(queryset=MicroGigCategory.objects.all())
    category_details = MicroGigCategorySerializer(source='category', read_only=True)
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
        
class MicroGigPostDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = MicroGigPost
        depth = 1
        exclude = ['user']

class BalanceSerializer(serializers.ModelSerializer):
    user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())
    user_details = UserSerializer(source='user', read_only=True)
    to_user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all(), required=False, allow_null=True)
    to_user_details = UserSerializer(source='to_user', read_only=True)
    class Meta:
        model = Balance
        fields = '__all__'

class ClassifiedPostSerializer(serializers.ModelSerializer):
    category = serializers.PrimaryKeyRelatedField(queryset=ClassifiedCategory.objects.all())
    category_details = ClassifiedServicesSerializer(source='category', read_only=True)
    user = UserSerializerGet(read_only=True)
    class Meta:
        model = ClassifiedCategoryPost
        fields = '__all__'
        depth = 1

class logoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Logo
        fields = '__all__'

class AuthenticationBannerSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuthenticationBanner
        fields = '__all__'

class AdminNoticeSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdminNotice
        fields = '__all__'
        def to_representation(self, instance):
            representation = super().to_representation(instance)
            return representation

    # def validate_category(self, value):
    #     try:
    #         category = ClassifiedCategory.objects.get(id=value)
    #     except ClassifiedCategory.DoesNotExist:
    #         raise serializers.ValidationError("Invalid category ID")
    #     return category

    # def create(self, validated_data):
    #     validated_data['category'] = validated_data.pop('category')
    #     return super().create(validated_data)



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



from rest_framework import serializers
from .models import Product, ProductCategory, ProductMedia

class ProductMediaSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductMedia
        fields = '__all__'

class ProductCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductCategory
        fields = '__all__'

class ProductSerializer(serializers.ModelSerializer):
    category_details = ProductCategorySerializer(source='category', read_only=True)
    image_details = ProductMediaSerializer(source='image', many=True, read_only=True)
    owner_details = UserSerializer(source='owner', read_only=True)
    
    class Meta:
        model = Product
        fields =  '__all__'
    
    # def to_representation(self, instance):
    #     representation = super().to_representation(instance)
    #     representation['regular_price'] = instance.sale_price
    #     if instance.discount_price > 0:
    #         representation['old_price'] = instance.sale_price
    #         representation['price'] = instance.discount_price
    #     else:
    #         representation['price'] = instance.sale_price
    #     return representation

class ProductMinSerializer(serializers.ModelSerializer):
    """Minimal product information for order items"""
    class Meta:
        model = Product
        fields = ['id', 'name', 'sale_price', 'image']

class OrderItemSerializer(serializers.ModelSerializer):
    product_details = ProductMinSerializer(source='product', read_only=True)
    
    class Meta:
        model = OrderItem
        fields = ['id', 'order', 'product', 'product_details', 'quantity', 'price', 'created_at']
        
    def validate_quantity(self, value):
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than 0")
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
            raise serializers.ValidationError("Total amount cannot be negative")
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
        user_product_ids = Product.objects.filter(owner=user).values_list('id', flat=True)
        
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
        model= Faq
        fields = ('label', 'content')
        