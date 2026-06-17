import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_app/layers/presentation/widgets/app_logo.dart';
import 'package:note_app/routes/app_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 30),
            SizedBox(width: 10),
            Text('Quest Notes'),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFromLocation(location),
        onDestinationSelected: (index) =>
            context.go(AppRoute.values[index].path),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Task',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Flashcard',
          ),
        ],
      ),
    );
  }

  int _indexFromLocation(String location) {
    final index = AppRoute.values.indexWhere(
      (route) => location.startsWith(route.path),
    );
    return index == -1 ? 0 : index;
  }
}
