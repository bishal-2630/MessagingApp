from rest_framework import status
from django.shortcuts import render
from django.http import JsonResponse
from rest_framework.views import APIView
from .serializers import UserSerializer
from rest_framework.response import Response
from django.contrib.auth import authenticate
from rest_framework.authtoken.models import Token

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
            token, created = Token.objects.get_or_create(user=user)
            return Response({'token': token.key,'user_id': user.id, 'username': user.username})
        return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)