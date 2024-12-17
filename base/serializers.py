from rest_framework import serializers
from .models import *
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.exceptions import ValidationError
from django.contrib.auth.hashers import make_password



class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        # Exclude the password field for security
        exclude = ('groups', 'user_permissions')
        extra_kwargs = {
            'password': {'write_only': True},
            # 'username': {'read_only': True},
        }

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise ValidationError(
                {"error": "This email is already registered."})
        return value

    def create(self, validated_data):
        # Hash the password
        validated_data['password'] = make_password(validated_data['password'])
        return User.objects.create(**validated_data)
    def to_representation(self, instance):
        """Customize the serialized output."""
        representation = super().to_representation(instance)
        # Remove the password field from the output
        representation.pop('password', None)
        return representation
    

class MicroGigPostTaskSerializer(serializers.ModelSerializer):
    gig = serializers.PrimaryKeyRelatedField(queryset=MicroGigPost.objects.all())
    user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())
    class Meta:
        model = MicroGigPostTask
        fields = '__all__'
        depth = 1

class GetMicroGigPostTaskSerializer(serializers.ModelSerializer):
    user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())
    class Meta:
        model = MicroGigPostTask
        fields = '__all__'
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
    class Meta:
        model = Balance
        fields = '__all__'

class ClassifiedPostSerializer(serializers.ModelSerializer):
    category = serializers.PrimaryKeyRelatedField(queryset=ClassifiedCategory.objects.all())
    category_details = ClassifiedServicesSerializer(source='category', read_only=True)

    class Meta:
        model = ClassifiedCategoryPost
        fields = '__all__'
        depth = 1

class logoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Logo
        fields = '__all__'

class AdminNoticeSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdminNotice
        fields = '__all__'
        def to_representation(self, instance):
            representation = super().to_representation(instance)
        # Format created_at to a human-readable format
            if 'created_at' in representation and instance.created_at:
                representation['created_at'] = instance.created_at.strftime("%A, %B %d, %Y %I:%M %p")
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