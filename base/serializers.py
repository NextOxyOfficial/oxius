from rest_framework import serializers
from .models import ClassifiedCategory,User
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken

class ClassifiedServicesSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClassifiedCategory
        fields = '__all__'

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = get_user_model()
        # Exclude the password field for security
        exclude = ('password', 'nid',)

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