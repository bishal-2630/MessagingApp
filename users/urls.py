from users.views import UserListView
from unicodedata import name
from users.views import ProfileView
from django.urls import path
from . import views 
from .views import RegisterView, LoginView
from rest_framework.routers import DefaultRouter
from .views import UserViewSet

router = DefaultRouter()
router.register('users', views.UserViewSet, basename='user')

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('profile/', ProfileView.as_view(), name='profile'),
] + router.urls
