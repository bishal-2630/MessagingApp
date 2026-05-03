from django.urls import path 
from . import views

urlpatterns = [
    path('messages/', views.message_list),
    path('messages/<int:pk>/', views.message_detail),
]