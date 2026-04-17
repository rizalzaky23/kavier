import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../kasir/presentation/screens/kasir_screen.dart';
import '../../../products/presentation/screens/products_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.grid_view_rounded,      label: 'Dashboard', screen: const DashboardScreen()),
    _NavItem(icon: Icons.point_of_sale_rounded,  label: 'Kasir',     screen: const KasirScreen()),
    _NavItem(icon: Icons.inventory_2_outlined,   label: 'Produk',    screen: const ProductsScreen()),
    _NavItem(icon: Icons.bar_chart_rounded,      label: 'Laporan',   screen: const ReportsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final user   = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide
          ? Row(children: [
              _buildSidebar(user),
              Expanded(child: _navItems[_selectedIndex].screen),
            ])
          : _navItems[_selectedIndex].screen,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primary.withOpacity(0.12),
              destinations: _navItems
                  .map((n) => NavigationDestination(
                        icon:       Icon(n.icon),
                        label:      n.label,
                        selectedIcon: Icon(n.icon, color: AppColors.primary),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildSidebar(user) {
    return Container(
      width: 240,
      color: AppColors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding:    const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
              ),
            ),
            child: Row(children: [
              const Icon(Icons.point_of_sale_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text('POS App',
                  style: GoogleFonts.inter(
                    color:      Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize:   18,
                  )),
            ]),
          ),

          // User info
          if (user != null)
            Container(
              margin:  const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius:          18,
                  backgroundColor: AppColors.primary,
                  child:           Text(user.name[0].toUpperCase(),
                      style: const TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize:   13,
                          ),
                          overflow: TextOverflow.ellipsis),
                      Text(user.role.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color:    AppColors.primary,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              ]),
            ),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding:     const EdgeInsets.symmetric(horizontal: 12),
              itemCount:   _navItems.length,
              itemBuilder: (_, i) {
                final selected = i == _selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading:  Icon(_navItems[i].icon,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary),
                    title: Text(_navItems[i].label,
                        style: GoogleFonts.inter(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 14,
                        )),
                    selected:      selected,
                    selectedTileColor: AppColors.primary.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onTap: () => setState(() => _selectedIndex = i),
                  ),
                );
              },
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon:     const Icon(Icons.logout_rounded),
                label:    const Text('Keluar'),
                style:    OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding:         const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String   label;
  final Widget   screen;
  const _NavItem({required this.icon, required this.label, required this.screen});
}
