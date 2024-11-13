import 'dart:developer';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  Future<void> requestPermission() async {
    //Instantiate FCM
    final settings = await getrequest();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log("The user has accepted push notification",
          name: "PUSH_NOTIFICATION_STATUS");
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      log("The user has denied push notification",
          name: "PUSH_NOTIFICATION_STATUS");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      log("The user has provisional access to push notification",
          name: "PUSH_NOTIFICATION_STATUS");
    }
  }

  Future<NotificationSettings> getrequest() async {
    final NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return settings;
  }

  Future<String> getToken() async {
    final _firebaseMessaging = await FirebaseMessaging.instance;
    if (Platform.isIOS) {
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken != null) {
        return await FirebaseMessaging.instance.getToken() ?? '';
      } else {
        await Future<void>.delayed(
          const Duration(
            seconds: 3,
          ),
        );
        apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          return await FirebaseMessaging.instance.getToken() ?? '';
        } else {
          return '';
        }
      }
    } else {
      return await FirebaseMessaging.instance.getToken() ?? '';
    }
  }

  void handleMessage(RemoteMessage message) {
    log(message.data.toString(), name: 'NOTIFICATION');
    // NotificationNavigation.mapRoute(jsonDecode(message.data['data']));
  }

  Future<void> setupInteractedMessage() async {
    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      await Future.delayed(const Duration(seconds: 5), () {
        handleMessage(initialMessage);
      });
    }

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    // await flutterLocalNotificationsPlugin
    //     .resolvePlatformSpecificImplementation<
    //         AndroidFlutterLocalNotificationsPlugin>()
    //     ?.createNotificationChannel(channel);
  }

  void initInfo() async {
    //   <meta-data
    // android:name="com.google.firebase.messaging.default_notification_channel_id"
    // android:value="high_importance_channel" />
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    const androidInitialize =
        AndroidInitializationSettings("@mipmap/ic_launcher");
    const iosInitialize = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // onDidReceiveLocalNotification: (id, title, body, payload) async {},
    );
    const initializationSettings =
        InitializationSettings(android: androidInitialize, iOS: iosInitialize);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // handleMessage(details.)
        log(details.payload.toString());
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      log('MESSAGE RECEIVED');
      final RemoteNotification? notification = message.notification;
      final AndroidNotification? android = message.notification?.android;

      if (notification != null)
        log(notification.title ?? '', name: 'NOTIFICATION RECEIVED');

      if (notification != null && android != null) {
        // final Map<String, dynamic> data = jsonDecode(message.data['data']);
        await flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(channel.id, channel.name,
                  importance: Importance.max,
                  icon: android.smallIcon,
                  channelDescription: channel.description),
            ));
      }
    });
  }

  //method used in triggerring firebase background messaging
  @pragma('vm:entry-point')
  Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();

    debugPrint("${message.messageId}" + " HANDLING A BACKGROUND MESSAGE");
    final RemoteNotification? notification = message.notification;
    final AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      // final Map<String, dynamic> data = jsonDecode(message.data['data']);
      await flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(channel.id, channel.name,
                importance: Importance.max,
                icon: android.smallIcon,
                channelDescription: channel.description),
          ));
    }
  }
}
