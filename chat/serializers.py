from rest_framework import serializers
from .models import Conversation,Message
from users.serializers import UserSerializer

class MessageSerializer(serializers.ModelSerializer):
    sender_username = serializers.ReadOnlyField(source='sender.username')
    class Meta:
        model = Message
        fields = ['id','conversation','sender','sender_username','content','is_delivered', 'is_read', 'created_at']
        extra_kwargs = {
            'sender' : {'read_only':True}
        }

class ConversationSerializer(serializers.ModelSerializer):
    participants = UserSerializer(many=True, read_only=True)
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    
    
    def get_last_message(self, obj):
        last_msg = obj.messages.order_by('-created_at').first()
        return MessageSerializer(last_msg).data if last_msg else None
    
    def get_unread_count(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return 0
        return obj.messages.exclude(sender=request.user).filter(is_read=False).count()

    class Meta:
        model = Conversation
        fields = ['id','participants','last_message', 'unread_count', 'created_at']
