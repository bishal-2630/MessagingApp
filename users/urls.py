from django.urls import path
from . import views 
from .views import RegisterView, LoginView, ProfileView, UserViewSet
from rest_framework.routers import DefaultRouter


router = DefaultRouter()
router.register('users', views.UserViewSet, basename='user')

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('profile/', ProfileView.as_view(), name='profile'),
] + router.urls
