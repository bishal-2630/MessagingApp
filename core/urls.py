
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
def health_check(request):
    return JsonResponse({"status": "online", "message": "MessagingApp Backend Server is Running!"})

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('users.urls')),
    path('api/', include('chat.urls')),
    
]
