# jele_test

An Application to send notifications

Libraries

- flutter_local_notifications: This is used to display notifications
- firebase_core: This is the firebase core package. We use firebase to send
  notifications so we need the core package
- firebase_messaging: This is used to receive the notifications
- permission_handler: This is used to manage permissions to allow or deny
  notifications

The app has one screen; When opened the app fetches the device token [Device
token is used for sending notifications to a specific device] and displays it on
the homescreen
