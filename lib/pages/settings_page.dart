import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_mess/themes/theme_provider.dart';
import 'package:provider/provider.dart';

import 'blocked_users_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("S E T T I N G S"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: Column(
        //dark mode
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(left: 25, top: 10, right: 25),
              padding: const EdgeInsets.only(
                  left: 25, bottom: 20, top: 20, right: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Dark Mode",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary),
                  ),
                  CupertinoSwitch(
                    value: Provider.of<ThemeProvider>(context, listen: false)
                        .isDarkMode,
                    onChanged: (value) =>
                        Provider.of<ThemeProvider>(context, listen: false)
                            .toggleTheme(),
                  ),
                ],
              ),
            ),
          ),

          //block user
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(left: 25, top: 10, right: 25),
              padding: const EdgeInsets.only(
                  left: 25, bottom: 20, top: 20, right: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Blocked User",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary),
                  ),
                  //button to go to blocked user page
                  IconButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BlockedUsersPage())),
                      icon:  Icon(Icons.arrow_forward_rounded,color: Theme.of(context).colorScheme.primary,))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
