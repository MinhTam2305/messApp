import 'package:flutter/material.dart';
import 'package:my_mess/components/my_drawer.dart';
import 'package:my_mess/components/user_title.dart';
import 'package:my_mess/services/auth/auth_service.dart';
import 'package:my_mess/services/chat/chat_service.dart';

import 'chat_page.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

//chat and auth service

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Home")),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
        stream: _chatService.getUsersStreamExcludingBlocked(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text("Error");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading . . .");
          }
          return ListView(
            children: snapshot.data!
                .map<Widget>(
                    (userData) => _buildUserListItem(userData, context))
                .toList(),
          );
        });
  }

  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    if (userData["email"] != _authService.getCurrentUser()!.email) {
      return UserTitle(
          text: userData["email"],
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatPage(
                          receiverEmail: userData["email"],
                          receiverID: userData["uid"],
                        )));
          });
    } else {
      return Container();
    }
  }
}
