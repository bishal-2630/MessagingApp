from rest_framework import viewsets, status
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from .models import Conversation, Message
from .serializers import ConversationSerializer, MessageSerializer

User = get_user_model()

class ConversationViewSet(viewsets.ModelViewSet):
    serializer_class = ConversationSerializer
    def get_queryset(self):
        return Conversation.objects.filter(participants=self.request.user)

    def create(self, request):
        target_user_id = request.data.get('target_user_id')
        if not target_user_id:
            return Response({'error': 'Target user ID is required.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            target_user = User.objects.get(id=target_user_id)
        except User.DoesNotExist:
            return Response({'error': 'Target user not found.'}, status=status.HTTP_404_NOT_FOUND)

        conversation = Conversation.objects.filter(participants=request.user).filter(participants=target_user).first()
        if conversation:
            serializer = ConversationSerializer(conversation)
            return Response(serializer.data)
        new_conv = Conversation.objects.create()
        new_conv.participants.add(request.user, target_user)
        serializer = ConversationSerializer(new_conv)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class MessageViewSet(viewsets.ModelViewSet):
    serializer_class = MessageSerializer
    def get_queryset(self):
        conversation_id = self.request.query_params.get('conversation')
        if not conversation_id:
            return Message.objects.none()
        return Message.objects.filter(conversation_id=conversation_id).order_by('created_at')

    def perform_create(self, serializer):
        serializer.save(sender=self.request.user)