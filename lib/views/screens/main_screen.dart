import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/upgrade_service.dart';
import 'library_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'spaced_repetition_screen.dart';
import 'ai_tools_screen.dart'; // Import the new screen
import '../../models/user_model.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Add AiToolsScreen to the list of widgets
  static const List<Widget> _widgetOptions = <Widget>[
    LibraryScreen(),
    SpacedRepetitionScreen(),
    AiToolsScreen(), // The new screen
    ProgressScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<UpgradeService>().listenToPurchaseUpdates(context);
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel?>(context);

    if (userModel == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Review',
          ),
          // Add the new navigation item
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
