from django.urls import include, path, re_path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    TokenVerifyView,
)

from .cities_light_views import CityViewSet, CountryViewSet, RegionViewSet
from .pay import *
from .views import *

router = DefaultRouter()
router.register(r"cities", CityViewSet)
router.register(r"regions", RegionViewSet)
router.register(r"countries", CountryViewSet)


urlpatterns = [
    path("logo/", getLogo, name="logo"),
    path("eshop-logo/", get_eshop_logo, name="eshop_logo"),
    path("faq/", get_faq, name="faq"),
    path(
        "authentication-banner/", getAuthenticationBanner, name="authenticationBanner"
    ),
    path("admin-notice/", getAdminNotice, name="admin_notice"),
    path("auth/register/", register, name="register_person"),
    path("user/<str:id>/", PersonRetrieveView.as_view(), name="person_detail"),
    path("top-contributors/", get_top_contributors, name="top_contributors"),
    path(
        "persons/<str:email>/",
        PersonRetrieveUpdateDestroyView.as_view(),
        name="person_detail",
    ),
    path(
        "persons/<str:email>/delete_image/",
        PersonImageDeleteView.as_view(),
        name="person-delete-image",
    ),
    path("persons/update/<str:email>/", update_user, name="update_user"),
    path(
        "user/<str:identifier>/",
        get_user_with_identifier,
        name="get_user_with_identifier",
    ),
    path("classified-categories/", GetClassifiedCategories.as_view()),
    re_path(
        r"^details/classified-categories/(?P<slug>[\w\-\u0980-\u09FF]+)/$",
        ClassifiedCategoryDetailView.as_view(),
        name="classified-category-detail",
    ),
    path("classified-categories-all/", GetClassifiedCategoriesAll.as_view()),
    path("classified-categories/<str:cid>/", classifiedCategoryPosts),
    path(
        "classified-categories/post/<str:slug>/",
        classifiedCategoryPost,
        name="classified-post-detail",
    ),
    path("classified-categories-post/", post_classified_service),
    path("user-classified-categories-post/", UserClassifiedCategoryPosts),
    path(
        "classified-posts/", GetClassifiedPosts.as_view(), name="get-classified-posts"
    ),
    path("micro-gigs-categories/", GetMicroGigCategory.as_view()),
    path("target-network/", GetTargetNetwork.as_view()),
    path("target-device/", GetTargetDevice.as_view()),
    path("target-country/", GetTargetCountry.as_view()),
    path("micro-gigs/", GetMicroGigs.as_view()),
    path(
        "classified-posts/filter/",
        ClassifiedCategoryPostFilterView.as_view(),
        name="classified_posts_filter",
    ),
    path(
        "delete-user-classified-post/<str:pk>/",
        delete_classified_post,
        name="user-classified-post",
    ),
    path(
        "update-user-classified-post/<str:pk>/",
        update_classified_post,
        name="user-classified-post",
    ),
    # User Micro Gigs Start
    path("user-micro-gigs/<str:pk>/", getUserMicroGigs, name="user-micro-gigs"),
    path("get-user-micro-gig/<str:pk>/", get_micro_gig_post, name="user-micro-gig"),
    path(
        "delete-user-micro-gig/<str:pk>/", delete_micro_gig_post, name="user-micro-gig"
    ),
    path(
        "update-user-micro-gig/<str:pk>/", update_micro_gig_post, name="user-micro-gig"
    ),
    path("post-micro-gigs/", post_micro_gigs, name="post_micro_gig-tasks"),
    # User micro-gigs Ends
    path(
        "user-micro-gig-tasks/<str:email>/",
        getMicroGigPostTasks,
        name="user_micro-gigs",
    ),
    re_path(
        r"^micro-gigs/(?P<gid>[\w\-\u0980-\u09FF]+)/$",
        gigDetails,
        name="gig-details",
    ),
    path("user-pending-tasks/", getPendingTasks, name="user_pending-tasks"),
    path(
        "user-micro-gig-task-post/",
        postMicroGigPostTask,
        name="user_micro-gig-task-post",
    ),
    path(
        "task-by-micro-gig-post/<uuid:gig_id>/tasks/",
        get_microgigpost_tasks,
        name="microgigpost-tasks",
    ),
    path(
        "update-task-by-micro-gig-post/<uuid:gig_id>/tasks/",
        update_microgigpost_tasks,
        name="microgigpost-tasks-update",
    ),
    path("user-balance/<str:email>/", UserBalance.as_view()),
    path(
        "received-transfers/",
        ReceivedTransfersView.as_view(),
        name="received-transfers",
    ),
    path(
        "purchase-product-slots/", purchase_product_slots, name="purchase-product-slots"
    ),
    path("add-user-balance/", postBalance),
    path("get-user-nid/", get_nid),
    path("add-user-nid/", add_nid),
    path("update-user-nid/", update_nid),
    path("admin-notice/", AdminMessage.as_view()),
    path(
        "admin-notice/<int:notice_id>/mark-read/",
        markAdminNoticeAsRead,
        name="mark-admin-notice-read",
    ),
    path("auth/token/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("auth/login/", CustomTokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("auth/validate-token/", TokenValidationView.as_view(), name="validate_token"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("auth/token/verify/", TokenVerifyView.as_view(), name="token_verify"),
    # payment
    path("pay/", makePayment),
    # ?amount=1000&order_id=001&currency=BDT&customer_name=Mahabubul+Hasan&customer_address=Mohakhali&customer_phone=01311310975&customer_city=Dhaka&customer_post_code=1229
    path("verify-pay/", verifyPayment),
    # ?sp_order_id=ADSYCLUB_67613e32050d9
    path("cities-light/", include(router.urls)),
    path("thana/", police_station, name="thana"),
    # division, distrct, policestation
    # path('district/<str:district_id>/police_stations/', get_police_stations, name='police_station'),
    # user's address
    path("change-password/", change_password, name="change-password"),
    # subscription
    path("subscribe/", subscribeToPro, name="subscribe"),
    # sms and otp
    path("send-sms/", smsSend),
    path("send-otp/", sendOTP),
    path("verify-otp/", verifyOTP),
    path("reset-password/", resetPassword),
    path("api/auth/reset-password/", reset_password_request),
    path("api/auth/verify-reset-otp/", verify_reset_otp),
    path("api/auth/set-new-password/", set_new_password),
    # product      # Product URLs
    path("all-products/", AllProductsListView.as_view(), name="all-products"),
    path("my-products/", UserProductsListView.as_view(), name="user-products"),
    path(
        "my-products/stats/", UserProductStatsView.as_view(), name="user-product-stats"
    ),
    path(
        "store/<str:store_username>/", StoreDetailsView.as_view(), name="store-details"
    ),
    path(
        "store/<str:store_username>/products/",
        StoreProductsListView.as_view(),
        name="store-products",
    ),
    path("products/", ProductListCreateView.as_view(), name="product-list-create"),
    re_path(
        r"^products/(?P<slug>[\w\-\u0980-\u09FF]+)/$",
        ProductDetailView.as_view(),
        name="product-detail",
    ),
    path(
        "products/featured/",
        FeaturedProductsListView.as_view(),
        name="featured-products",
    ),
    path(
        "product/order-count/<uuid:product_id>/",
        product_order_count,
        name="product_order_count",
    ),
    # Product Category URLs
    path(
        "product-categories/",
        ProductCategoryListCreateView.as_view(),
        name="product-category-list-create",
    ),
    path(
        "product-categories/details/<slug:slug>/",
        ProductCategoryDetailsBySlug.as_view(),
        name="product-category-details-slug",
    ),
    path(
        "product-categories/<int:pk>/",
        ProductCategoryDetailView.as_view(),
        name="product-category-detail",
    ),
    path("orders/", OrderListCreate.as_view(), name="order-list-create"),
    path("orders/<uuid:id>/", OrderDetail.as_view(), name="order-detail"),
    path(
        "orders/<uuid:id>/update/", OrderWithItemsUpdate.as_view(), name="order-update"
    ),
    path("orders/search/", OrderSearch.as_view(), name="order-search"),
    path("users/<uuid:user_id>/orders/", UserOrdersList.as_view(), name="user-orders"),
    path(
        "orders/create-with-items/",
        OrderWithItemsCreate.as_view(),
        name="create-order-with-items",
    ),
    path("seller-orders/", SellerOrdersView.as_view(), name="seller-orders"),
    path(
        "seller-orders/stats/",
        SellerOrderStatsView.as_view(),
        name="seller-order-stats",
    ),
    # OrderItem endpoints
    path("order-items/<uuid:id>/", OrderItemDetail.as_view(), name="order-item-detail"),
    path("order-items/search/", OrderItemSearch.as_view(), name="order-item-search"),
    path(
        "orders/<uuid:order_id>/items/",
        OrderItemsByOrder.as_view(),
        name="order-items-by-order",
    ),
    path(
        "check-store-username/",
        check_store_username_availability,
        name="check-store-username",
    ),
    # banner image
    path("banner-images/", BannerImageListView.as_view(), name="banner-image"),
    path(
        "shop-banner-images/",
        ShopBannerImageListView.as_view(),
        name="shop-banner-image",
    ),
    path("referred-users/", referred_users, name="referred-users"),
    path("commission-history/", commission_history, name="commission-history"),
    path(
        "platform-referral-stats/",
        platform_referral_stats,
        name="platform-referral-stats",
    ),
    path("bn-logo/", BNLogoView.as_view(), name="bn-logo"),
    path("news-logo/", NewsLogoView.as_view(), name="news-logo"),
    # Diamond API endpoints
    path(
        "diamonds/packages/",
        DiamondPackageListView.as_view(),
        name="diamond_package_list",
    ),
    path(
        "diamonds/purchase/", PurchaseDiamondsView.as_view(), name="purchase_diamonds"
    ),
    # Product slots API endpoints
    path(
        "product-slot-packages/",
        ProductSlotPackageListView.as_view(),
        name="product_slot_package_list",
    ),
    path(
        "diamonds-transactions/",
        DiamondTransactionListView.as_view(),
        name="diamond_transactions",
    ),
    path(
        "business-network/send-diamond-gift/",
        SendDiamondGiftView.as_view(),
        name="send_diamond_gift",
    ),
    path(
        "diamonds/send-gift/", SendDiamondGiftView.as_view(), name="send_diamond_gift"
    ),
    # eshop banner
    path("eshop-banner/", EshopBannerListView.as_view(), name="eshop_banner"),
    path(
        "eshop-banner/mobile/",
        MobileBannerListView.as_view(),
        name="mobile_eshop_banner",
    ),
    # Android app version
    path("android-app/latest/", get_latest_android_app, name="android_app_latest"),
    # AILink
    path("ai-link/", AILinkView.as_view(), name="ai_link"),
    path("country-version/", CountryVersionListView.as_view(), name="country_version"),
]
