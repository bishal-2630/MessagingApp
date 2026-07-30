from .models import User 
from chat.models import FCMDeviceToken
from functools import partial
from users.serializers import ProfileSerializer
from rest_framework import status, viewsets
from django.shortcuts import render
from django.http import JsonResponse
from rest_framework.views import APIView
from .serializers import UserSerializer
from rest_framework.response import Response
from django.contrib.auth import authenticate
from django.utils import timezone
from rest_framework.authtoken.models import Token
from rest_framework_simplejwt.tokens import RefreshToken


class RegisterView(APIView):
    permission_classes = []
    def post(self, request):
        serializer = UserSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    permission_classes = []
    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')
        user = authenticate(request, username=email, password=password)
        if user:
            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user_id': user.id,
                'username': user.username,
            })
        return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

class ProfileView(APIView):
    def get(self, request):
        user = request.user
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    def put(self, request):
        profile = request.user.profile  
        serializer = ProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class UserViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class UserSearchView(APIView):
    def get(self,request):
        username= request.query_params.get('username')
        if not username:
            return Response({'No Match Found '}, status= status.HTTP_400_BAD_REQUEST)

        user = User.objects.filter(username__iexact=username).exclude(id=request.user.id).first()

        if not user:
            return Response({'No User Found.'}, status=status.HTTP_404_NOT_FOUND)
        
        serializer = UserSerializer(user)
        return Response(serializer.data)
        

class RegisterFCMTokenView(APIView):
    def post(self, request):
        token = request.data.get('token')
        if not token:
            return Response({'Error': 'Token is required.'},status=status.HTTP_400_BAD_REQUEST)

        obj, created = FCMDeviceToken.objects.update_or_create(
            token=token,
            defaults={'user': request.user}
            )
        return Response({'Success': 'Token registered successfully.'},status=status.HTTP_200_OK)


class UserStatusView(APIView):
    def get(self, request, user_id):
        try:
            from .models import Profile
            profile = Profile.objects.get(user_id=user_id)
            if profile.is_online:
                return Response({'is_online': True, 'last_seen': ''})
            diff = timezone.now() - profile.last_active
            minutes = int(diff.total_seconds() / 60)
            if minutes < 1:
                last_seen = 'Last seen just now'
            elif minutes < 60:
                last_seen = f'Last seen {minutes}m ago'
            elif minutes < 1440:
                hours = int(minutes / 60)
                last_seen = f'Last seen {hours}h ago'
            else:
                days = minutes // 1440
                last_seen = f'Last seen {days}d ago'
            return Response({'is_online': False, 'last_seen': last_seen})
        except Exception:
            return Response({'is_online': False, 'last_seen': ''})