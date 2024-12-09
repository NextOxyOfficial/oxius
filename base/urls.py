from django.urls import path
from .views import *
from rest_framework_simplejwt.views import (TokenObtainPairView,TokenRefreshView,TokenVerifyView)

urlpatterns = [
  path('auth/register/', register, name='register_person'),
  path('persons/<str:email>/', PersonRetrieveUpdateDestroyView.as_view(),name='person_detail'),
  path('persons/update/<str:email>/', update_user,name='update_user'),
  path('classified-categories/',GetClassifiedCategories.as_view()),
  path('classified-categories/<str:cid>/',classifiedCategoryPosts),
  path('classified-categories/post/<str:pid>/',classifiedCategoryPost),
  path('classified-categories-post/',post_classified_service),
  path('micro-gigs-categories/',GetMicroGigCategory.as_view()),
  path('target-network/',GetTargetNetwork.as_view()),
  path('target-device/',GetTargetDevice.as_view()),
  path('target-country/',GetTargetCountry.as_view()),
  path('micro-gigs/',GetMicroGigs.as_view()),
  path('post-micro-gigs/',post_micro_gigs, name='post_micro_gigs'),
  path('micro-gigs/<str:gid>/',gigDetails),
  path('user-balance/<str:email>/',UserBalance.as_view()),
  path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
  path('auth/login/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
  path('auth/validate-token/', TokenValidationView.as_view(), name='validate_token'),
  path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
  path('auth/token/verify/', TokenVerifyView.as_view(), name='token_verify'),
]