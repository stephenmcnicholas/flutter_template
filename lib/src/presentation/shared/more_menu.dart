import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoreMenu extends StatelessWidget {
  const MoreMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/profile');
            },
          ),
        ],
      ),
    );
  }
} 