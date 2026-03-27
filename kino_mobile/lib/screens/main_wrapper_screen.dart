import 'dart:ui';

import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _selectedIndex = 0;
  final List<int> _tabHistory = <int>[];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _tabHistory.add(_selectedIndex);
      _selectedIndex = index;
    });
  }

  void _goBackToPreviousTab() {
    if (_tabHistory.isNotEmpty) {
      setState(() {
        _selectedIndex = _tabHistory.removeLast();
      });
      return;
    }

    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  Future<bool> _handleWillPop() async {
    if (_selectedIndex != 0 || _tabHistory.isNotEmpty) {
      _goBackToPreviousTab();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeScreen(onNavigateToTab: _onItemTapped),
            SearchScreen(
              onNavigateToTab: _onItemTapped,
              onBackToPrevious: _goBackToPreviousTab,
            ),
            LibraryScreen(
              onNavigateToTab: _onItemTapped,
              onBackToPrevious: _goBackToPreviousTab,
            ),
          ],
        ),
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: const Color(0xFF121212).withOpacity(0.7),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: BottomNavigationBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                selectedItemColor: Colors.purpleAccent,
                unselectedItemColor: Colors.white30,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_filled),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search_rounded),
                    label: 'Search',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite),
                    label: 'Library',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
