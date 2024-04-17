import 'package:flutter/material.dart';
import 'package:i_mess/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUse;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUse,
  });

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        Provider
            .of<ThemeProvider>(context, listen: false)
            .isDarkMode;
    return Container(
        decoration: BoxDecoration(
        color: isCurrentUse
        ? (isDarkMode ? Colors.green.shade600 : Colors.green.shade500): (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
    borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 25),
    child: Text(
    message,
    style: TextStyle(color:isCurrentUse? Colors.white:( isDarkMode?Colors.white:Colors.black)),
    )
    ,
    );
  }
}
