import 'package:flutter/material.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../blog/screens/blog_list_screen.dart';
import '../../tools/screens/tools_screen.dart';
import '../../contacts/screens/contacts_screen.dart';
import '../../../core/theme/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabSelected,
          elevation: 0,
          backgroundColor: isDark ? AppColors.surfaceDark : null,
          indicatorColor: AppColors.brand.withValues(alpha: 0.12),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          animationDuration: const Duration(milliseconds: 300),
          destinations: [
            _NavDestination(
              index: 0,
              selectedIndex: _selectedIndex,
              icon: Icons.chat_bubble_outline_rounded,
              selectedIcon: Icons.chat_bubble_rounded,
              label: 'Chats',
            ),
            _NavDestination(
              index: 1,
              selectedIndex: _selectedIndex,
              icon: Icons.book_outlined,
              selectedIcon: Icons.book_rounded,
              label: 'Journal',
            ),
            _NavDestination(
              index: 2,
              selectedIndex: _selectedIndex,
              icon: Icons.grid_view_outlined,
              selectedIcon: Icons.grid_view_rounded,
              label: 'Tools',
            ),
            _NavDestination(
              index: 3,
              selectedIndex: _selectedIndex,
              icon: Icons.contacts_outlined,
              selectedIcon: Icons.contacts_rounded,
              label: 'Contacts',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavDestination extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavDestination({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NavigationDestination(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          icon,
          key: ValueKey('${icon}_$isSelected'),
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
      selectedIcon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          selectedIcon,
          key: ValueKey('${selectedIcon}_$isSelected'),
          color: AppColors.brand,
          size: 28,
        ),
      ),
      label: label,
    );
  }
}
