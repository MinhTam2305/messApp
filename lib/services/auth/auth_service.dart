import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../main.dart';

class AuthService {
  //instance of auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  //get user current
  User? getCurrentUser() {
    return _auth.currentUser;
  }

// Yêu cầu quyền thông báo
  Future<void> requestFer() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    handleBackground();
    handleForeground(); // Gọi hàm này để xử lý thông báo khi ứng dụng đang hoạt động
  }

// Khởi tạo thông báo cục bộ
  void initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

// Hiển thị thông báo trong thanh thông báo
  Future<void> showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'high_priority_channel', // ID kênh
      'Thông báo cao', // Tên kênh
      channelDescription: 'Kênh thông báo cho các thông báo quan trọng', // Mô tả kênh
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      icon: 'ic_launcher', // Tên biểu tượng không có đuôi
    );




    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // ID thông báo
      message.notification?.title, // Tiêu đề
      message.notification?.body, // Nội dung
      platformChannelSpecifics,
      payload: 'item x', // Dữ liệu bổ sung (nếu cần)
    );
  }

// Xử lý thông điệp
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    showNotification(message); // Hiển thị thông báo
  }

// Xử lý thông báo khi ứng dụng ở chế độ nền hoặc bị đóng
  Future<void> handleBackground() async {
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }

// Xử lý thông báo khi ứng dụng đang hoạt động
  void handleForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      handleMessage(message); // Gọi hàm handleMessage để hiển thị thông báo
    });
  }

// Đăng nhập
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    String? token = await _firebaseMessaging.getToken();
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Lưu thông tin người dùng vào tài liệu riêng
      _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'token': token
      });
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

//sign up
  Future<UserCredential> signUpWithEmailPassword(
      String email, String password) async {
    String? token = await _firebaseMessaging.getToken();
    try {
      //create user
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
//save user info in a separate doc
      _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'token': token,
      });
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //log out
  Future<void> logout() async {
    return await _auth.signOut();
  }

}
