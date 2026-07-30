from django.urls import path
from . import views 
from .views import RegisterView, LoginView, ProfileView, UserViewSet, UserSearchView, RegisterFCMTokenView
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from rest_framework.routers import DefaultRouter



router = DefaultRouter()
router.register('users', views.UserViewSet, basename='user')

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('users/search/', UserSearchView.as_view(), name='user_search'),
    path('fcm/token/', RegisterFCMTokenView.as_view(), name='register_fcm_token'),
    path('users/<int:user_id>/status/', views.UserStatusView.as_view(), name='user_status'),
] + router.urls
