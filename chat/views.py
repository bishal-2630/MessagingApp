from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import permission_classes
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token
from .models import Messages
from .serializers import MessageSerializer

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def message_list(request):
    if request.method == 'GET':
        sender_name = request.query_params.get('sender')
        if sender_name:
            messages = Messages.objects.filter(sender=sender_name)
        else:
            messages = Messages.objects.all()
        serializer = MessageSerializer(messages, many=True)
        return Response(serializer.data)

    elif request.method == 'POST':
        serializer = MessageSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

@api_view(['GET', 'DELETE', 'PUT', 'PATCH'])
def message_detail(request, pk):
    try:
        message = Messages.objects.get(pk=pk)
    except Messages.DoesNotExist:
        return Response(status=404)

    if request.method == 'GET':
        serializer = MessageSerializer(message)
        return Response(serializer.data)
    
    elif request.method == 'DELETE':
        message.delete()
        return Response(status=204)

    elif request.method in ['PUT', 'PATCH']:
        is_partial = (request.method == 'PATCH')

        serializer = MessageSerializer(message, data=request.data, partial=is_partial)

        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)

@api_view(['POST'])
def register_user(request):
    username = request.data.get('username')
    email = request.data.get('email')
    password = request.data.get('password')

    if User.objects.filter(username=username).exists():
        return Response({'error': 'Username already exists'}, status=400)

    user = User.objects.create_user(username=username, email=email, password=password)
    token, created = Token.objects.get_or_create(user=user)

    return Response({'token': token.key})
    