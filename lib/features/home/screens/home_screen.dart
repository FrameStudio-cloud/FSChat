import 'package:flutter/material.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../calls/screens/call_log_screen.dart';
import '../../contacts/screens/contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final _screens = const [
    ChatListScreen(),
    CallLogScreen(),
    ContactsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.phone_outlined),
            selectedIcon: Icon(Icons.phone_rounded),
            label: 'Calls',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts_rounded),
            label: 'Contacts',
          ),
        ],
      ),
    );
  }
}
