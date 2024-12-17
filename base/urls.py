from django.urls import path
from .views import *
from .pay import *
from rest_framework_simplejwt.views import (TokenObtainPairView,TokenRefreshView,TokenVerifyView)

urlpatterns = [
  path('logo/',getLogo,name='logo'),
  path('admin-notice/',getAdminNotice,name='admin_notice'),
  path('auth/register/', register, name='register_person'),
  path('persons/<str:email>/', PersonRetrieveUpdateDestroyView.as_view(),name='person_detail'),
  path('persons/update/<str:email>/', update_user,name='update_user'),
  path('classified-categories/',GetClassifiedCategories.as_view()),
  path('classified-categories/<str:cid>/',classifiedCategoryPosts),
  path('classified-categories/post/<str:pk>/',classifiedCategoryPost),
  path('classified-categories-post/',post_classified_service),
  path('micro-gigs-categories/',GetMicroGigCategory.as_view()),
  path('target-network/',GetTargetNetwork.as_view()),
  path('target-device/',GetTargetDevice.as_view()),
  path('target-country/',GetTargetCountry.as_view()),
  path('micro-gigs/',GetMicroGigs.as_view()),
  path('classified-posts/filter/', ClassifiedCategoryPostFilterView.as_view(), name='classified_posts_filter'),
  # User Micro Gigs Start
  path('user-micro-gigs/<str:pk>/',getUserMicroGigs,name='user-micro-gigs'),
  path('get-user-micro-gig/<str:pk>/',get_micro_gig_post,name='user-micro-gig'),
  path('delete-user-micro-gig/<str:pk>/',delete_micro_gig_post,name='user-micro-gig'),
  path('update-user-micro-gig/<str:pk>/',update_micro_gig_post,name='user-micro-gig'),
  path('post-micro-gigs/',post_micro_gigs, name='post_micro_gig-tasks'),
  # User micro-gigs Ends
  path('user-micro-gig-tasks/<str:email>/',getMicroGigPostTasks, name='user_micro-gigs'),
  path('micro-gigs/<str:gid>/',gigDetails),
  path('user-pending-tasks/',getPendingTasks, name='user_pending-tasks'),
  path('user-micro-gig-task-post/',postMicroGigPostTask, name='user_micro-gig-task-post'),
  path('task-by-micro-gig-post/<uuid:gig_id>/tasks/', get_microgigpost_tasks, name='microgigpost-tasks'),
  path('update-task-by-micro-gig-post/<uuid:gig_id>/tasks/', update_microgigpost_tasks, name='microgigpost-tasks-update'),

  path('user-balance/<str:email>/',UserBalance.as_view()),
  path('admin-notice/',AdminMessage.as_view()),
  path('auth/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
  path('auth/login/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
  path('auth/validate-token/', TokenValidationView.as_view(), name='validate_token'),
  path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
  path('auth/token/verify/', TokenVerifyView.as_view(), name='token_verify'),
  #payment
  path('pay/',makePayment), 
  # ?amount=1000&order_id=001&currency=BDT&customer_name=Mahabubul+Hasan&customer_address=Mohakhali&customer_phone=01311310975&customer_city=Dhaka&customer_post_code=1229
  path('verify-pay/',verifyPayment), 
  # ?sp_order_id=ADSYCLUB_67613e32050d9
]