import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Smart Inventory',
      subtitle: 'Organize your storage boxes with digital precision and AI insights.',
      image: Icons.inventory_2_rounded,
      color: AppTheme.primaryColor,
    ),
    OnboardingData(
      title: 'Scan & Identify',
      subtitle: 'Use QR codes and AI Vision to find items instantly without opening boxes.',
      image: Icons.qr_code_scanner_rounded,
      color: AppTheme.accentColor,
    ),
    OnboardingData(
      title: 'Detailed Insights',
      subtitle: 'Track value, quantity, and expiry dates of everything you own.',
      image: Icons.analytics_rounded,
      color: Colors.orange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _OnboardingPage(data: _pages[index]),
          ),
          Positioned(
            bottom: 60, left: 30, right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(_pages.length, (index) => _buildDot(index)),
                ),
                FloatingActionButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                    } else {
                      context.read<InventoryProvider>().finishOnboarding();
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
                    }
                  },
                  backgroundColor: _pages[_currentPage].color,
                  child: Icon(_currentPage == _pages.length - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            top: 60, right: 20,
            child: TextButton(
              onPressed: () {
                context.read<InventoryProvider>().finishOnboarding();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
              },
              child: const Text('Skip', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? _pages[_currentPage].color : Colors.grey.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData image;
  final Color color;

  OnboardingData({required this.title, required this.subtitle, required this.image, required this.color});
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: data.color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(data.image, size: 100, color: data.color),
          ),
          const SizedBox(height: 60),
          Text(
            data.title,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            data.subtitle,
            style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
