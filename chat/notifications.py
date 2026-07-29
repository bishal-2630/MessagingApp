import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
import os 

def init_firebase():
    if not firebase_admin._apps:
        cred_path = os.path.join(settings.BASE_DIR, 'serviceAccountKey.json')
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        else:
            try:
                firebase_admin.initialize_app()
            except Exception as e:
                print(f"Firebase Admin init note: {e}")

def send_push_notification(user, title, body, data=None):
    from chat.models import FCMDeviceToken
    tokens = list(FCMDeviceToken.objects.filter(user=user).values_list('token', flat=True))
    if not tokens:
        return

    init_firebase()
    for token in tokens:
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                token=token,
            )
            messaging.send(message)
        except Exception as e:
            print(f"Failed to send FCM notification to {user.username}: {e}")
            
        