from rest_framework import serializers
from .models import Conversation,Message
from users.serializers import UserSerializer

class MessageSerializer(serializers.ModelSerializer):
    sender_username = serializers.ReadOnlyField(source='sender.username')
    class Meta:
        model = Message
        fields = ['id','conversation','sender','sender_username','content','created_at']

class ConversationSerializer(serializers.ModelSerializer):
    participants = UserSerializer(many=True, read_only=True)
    last_message = serializers.SerializerMethodField()
    
    
    def get_last_message(self, obj):
        last_msg = obj.messages.order_by('-created_at').first()
        return MessageSerializer(last_msg).data if last_msg else None

    class Meta:
        model = Conversation
        fields = ['id','participants','last_message','created_at']
