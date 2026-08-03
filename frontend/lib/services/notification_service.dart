import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
    static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
    static final FlutterLocalNotificationsPlugin _localNotifications =
        FlutterLocalNotificationsPlugin();

    static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
    );

    // Set this to suppress notifications from the active chat screen
    static int? activeConversationId;

    static Future<void> init() async {
        await _fcm.requestPermission();

        FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

        const AndroidInitializationSettings androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        await _localNotifications.initialize(
            const InitializationSettings(android: androidSettings),
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            final convIdStr = message.data['conversationId'];
            if (convIdStr != null) {
                final incomingConvId = int.tryParse(convIdStr.toString());
                // Suppress popup if this notification belongs to the open chat screen
                if (incomingConvId != null && incomingConvId == activeConversationId) {
                    return;
                }
            }

            final notification = message.notification;
            if (notification != null) {
                _localNotifications.show(
                    notification.hashCode,
                    notification.title,
                    notification.body,
                    NotificationDetails(
                        android: AndroidNotificationDetails(
                            _channel.id,
                            _channel.name,
                            importance: Importance.max,
                            priority: Priority.high,
                        ),
                    ),
                );
            }
        });

        final token = await _fcm.getToken();
        if (token != null) {
            await ApiService.registerFCMToken(token);
        }
    }
}
