import 'package:flutter/material.dart';
import 'package:my_mess/components/user_title.dart';
import 'package:my_mess/services/auth/auth_service.dart';
import 'package:my_mess/services/chat/chat_service.dart';

class BlockedUsersPage extends StatelessWidget {
  BlockedUsersPage({super.key});

  final ChatService chatService = ChatService();
  final AuthService authService = AuthService();

  //show unblock box
  void _showUnblockBox(BuildContext context, String userId) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Unblock User"),
              content: const Text("Are you sure you want to unblock this user"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () {
                      chatService.unblockUser(userId);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("User Unblocked")));
                    },
                    child: const Text("Unblock")),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final userId = authService.getCurrentUser()!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLOCKED USERS"),
        actions: [],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.getBlockedUserStream(userId),
        builder: (context, snapshot) {
          //error
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading"));
          }
          //loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final blockedUsers = snapshot.data ?? [];
          //no user
          if (blockedUsers.isEmpty) {
            return const Center(child: Text("No blocked users"));
          }
          //load complete
          return ListView.builder(
              itemCount: blockedUsers.length,
              itemBuilder: (context, index) {
                final user = blockedUsers[index];
                return UserTitle(
                  text: user["email"],
                  onTap: () => _showUnblockBox(context,user['uid']),
                );
              });
        },
      ),
    );
  }
}
