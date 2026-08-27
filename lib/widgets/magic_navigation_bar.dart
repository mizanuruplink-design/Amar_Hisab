// lib/widgets/magic_navigation_bar.dart
import 'package:flutter/material.dart';
import 'magic_nav_button.dart';

class MagicNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isDarkMode;

  const MagicNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  State<MagicNavigationBar> createState() => _MagicNavigationBarState();
}

class _MagicNavigationBarState extends State<MagicNavigationBar> {
  late List<GlobalKey> _buttonKeys;
  double _indicatorLeft = 0;
  double _indicatorWidth = 0;
  bool _isInitialized = false;

  final List<Map<String, dynamic>> _menuItems = const [
    {'icon': Icons.home_outlined, 'label': 'হোম'},
    {'icon': Icons.calendar_month_outlined, 'label': 'ক্যালেন্ডার'},
    {'icon': Icons.notifications_none_outlined, 'label': 'নোটিশ'},
    {'icon': Icons.book_outlined, 'label': 'নোটবুক'},
    {'icon': Icons.person_outline_outlined, 'label': 'প্রোফাইল'},
  ];

  @override
  void initState() {
    super.initState();
    _buttonKeys = List.generate(_menuItems.length, (index) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndicatorPosition(widget.currentIndex);
      setState(() => _isInitialized = true);
    });
  }

  @override
  void didUpdateWidget(covariant MagicNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _updateIndicatorPosition(widget.currentIndex);
    }
  }

  void _updateIndicatorPosition(int index) {
    final RenderBox? renderBox =
    _buttonKeys[index].currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    setState(() {
      _indicatorLeft = position.dx + (size.width / 2) - 20;
      _indicatorWidth = 40;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 🔮 স্লাইডিং ইন্ডিকেটর
          if (_isInitialized)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              left: _indicatorLeft,
              bottom: 6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                width: _indicatorWidth,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isDarkMode
                        ? [Colors.teal.shade300, Colors.blue.shade300]
                        : [Colors.teal.shade600, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isDarkMode
                          ? Colors.teal.shade300.withOpacity(0.5)
                          : Colors.teal.shade600.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

          // 📱 বাটনসমূহ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_menuItems.length, (index) {
              return MagicNavButton(
                key: _buttonKeys[index],
                index: index,
                selectedIndex: widget.currentIndex,
                onTap: (i) {
                  widget.onTap(i);
                  _updateIndicatorPosition(i);
                },
                icon: _menuItems[index]['icon'],
                label: _menuItems[index]['label'],
                isDarkMode: widget.isDarkMode,
              );
            }),
          ),
        ],
      ),
    );
  }
}