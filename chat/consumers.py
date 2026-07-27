import json 
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from .models import Conversation, Message

User = get_user_model()

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.conversation_id = self.scope['url_route']['kwargs']['conversation_id']
        self.room_group_name = f'chat_{self.conversation_id}'
        user = self.scope.get('user')

        if not user or not user.is_authenticated:
            await self.close(code=4001)
            return

        is_participant = await self.check_participant(user, self.conversation_id)
        if not is_participant:
            await self.close(code=4003)
            return

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()
    
    async def disconnect(self, close_code):
        if hasattr(self, 'room_group_name'):
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )
    
    async def receive(self, text_data):
        try:
            data = json.loads(text_data)
            content = data.get('content', '').strip()
            if not content:
                return
            user = self.scope['user']
            msg = await self.save_message(user, self.conversation_id, content)
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                   'type': 'chat_message',
                   'id': msg.id ,
                   'conversation': int(self.conversation_id),
                   'sender': user.id,
                   'sender_username': user.username, 
                   'content': content, 
                   'created_at': msg.created_at.isoformat(), 
                }
            )
        except Exception as e:
            await self.send(text_data=json.dumps({'error': str(e)}))
    
    async def chat_message(self, event):
        await self.send(text_data=json.dumps(event))

    @database_sync_to_async
    def check_participant(self, user, conversation_id):
        try:
            conv = Conversation.objects.get(id=conversation_id)
            return conv.participants.filter(id=user.id).exists()
        except Conversation.DoesNotExist:
            return False
    
    @database_sync_to_async
    def save_message(self, user, conversation_id, content):
        conv = Conversation.objects.get(id=conversation_id)
        return Message.objects.create(
            conversation=conv,
            sender=user,
            content=content,
        )



        