from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import permission_classes
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token
from django.core.mail import send_mail
from django.conf import settings
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
    
    verification_link = f"http://10.0.2.2:8000/api/verify/?username={username}"

    send_mail(
        'Verify your Chat Me Account',
        f'Hi {username}, click here to verify: {verification_link}',
        settings.EMAIL_HOST_USER,
        [email], # <--- This is the user's real email!
        fail_silently=False,
    )
    return Response({'message': 'Check your email to verify your account!'})


@api_view(['GET'])
def verify_email(request):
    username = request.query_params.get('username')
    user = User.objects.get(username=username)
    user.is_active = True # <--- Unlock the account!
    user.save()
    return Response({"message": "Account verified! You can now login."})
