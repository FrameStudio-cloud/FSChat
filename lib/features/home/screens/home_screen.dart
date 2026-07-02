import 'package:flutter/material.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../blog/screens/blog_list_screen.dart';
import '../../tools/screens/tools_screen.dart';
import '../../contacts/screens/contacts_screen.dart';
import '../widgets/fsc_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _animController;

  final _screens = const [
    ChatListScreen(),
    BlogListScreen(),
    ToolsScreen(),
    ContactsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return;
    _animController.forward(from: 0);
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: FSCBottomNav(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
