from django.urls import path
from . import views 
from .views import RegisterView, LoginView, ProfileView, UserViewSet, UserSearchView, RegisterFCMTokenView, ForgotPasswordView, VerifyOTPView, ResetPasswordView, VerifyEmailView, ResendVerificationView, GoogleLoginView
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
    path('users/forgot-password/', ForgotPasswordView.as_view(), name='forgot_password'),
    path('users/verify-otp/', VerifyOTPView.as_view(), name='verify_otp'),
    path('users/reset-password/', ResetPasswordView.as_view(), name='reset_password'),
    path('forgot-password/', ForgotPasswordView.as_view(), name='forgot_password_alias'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify_otp_alias'),
    path('reset-password/', ResetPasswordView.as_view(), name='reset_password_alias'),
    path('users/verify-email/', VerifyEmailView.as_view(), name='verify_email'),
    path('users/resend-verification/', ResendVerificationView.as_view(), name='resend_verification'),
    path('users/google-login/', GoogleLoginView.as_view(), name='google_login'),
] + router.urls
