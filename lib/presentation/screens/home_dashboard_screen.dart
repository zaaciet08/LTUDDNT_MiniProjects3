import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/currency_format.dart';
import '../../models/expense_item.dart';
import '../widgets/expense_card.dart';
import 'scan_receipt_screen.dart';
import 'expense_list_screen.dart';
import 'statistics_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentIndex = 0;
  double _monthTotal = 0.0;
  double _allTimeTotal = 0.0;
  List<ExpenseItem> _recentExpenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await DatabaseHelper.instance.seedInitialDataIfEmpty();
    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final now = DateTime.now();
    final mTotal = await DatabaseHelper.instance.getMonthTotal(now.year, now.month);
    final allTotal = await DatabaseHelper.instance.getTotalAmount();
    final allList = await DatabaseHelper.instance.getAllExpenses();

    if (mounted) {
      setState(() {
        _monthTotal = mTotal;
        _allTimeTotal = allTotal;
        _recentExpenses = allList.take(5).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _openScanner() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ScanReceiptScreen()),
    );
    if (result == true) {
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboardHome(),
      const ExpenseListScreen(),
      const StatisticsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) _loadDashboardData();
        },
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF2563EB)),
            label: 'Tổng Quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF2563EB)),
            label: 'Sổ Quỹ',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart, color: Color(0xFF2563EB)),
            label: 'Biểu Đồ',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScanner,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.document_scanner),
        label: const Text(
          'Quét Hóa Đơn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDashboardHome() {
    final now = DateTime.now();

    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'VKU EXPENSE OCR',
                                    style: TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Quản Lý Chi Tiêu CLB',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _currentIndex = 2);
                          },
                          icon: const Icon(Icons.query_stats, color: Color(0xFF2563EB), size: 28),
                          tooltip: 'Xem Biểu Đồ Thống Kê',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Hero Monthly Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF38BDF8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'CHI TIÊU THÁNG ${now.month}/${now.year}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt, color: Colors.amberAccent, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'ML Kit AI',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            CurrencyHelper.format(_monthTotal),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.receipt, color: Colors.white70, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Tổng tất cả hóa đơn: ${CurrencyHelper.format(_allTimeTotal)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Action Banner
                    InkWell(
                      onTap: _openScanner,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quét Hóa Đơn Mới',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Tự động bóc tách số tiền, ngày, tên cửa hàng',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2563EB)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Recent Expenses Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Hóa Đơn Gần Đây',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _currentIndex = 1);
                          },
                          child: const Text('Xem tất cả', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (_recentExpenses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Text(
                          'Chưa có hóa đơn nào. Bấm "Quét Hóa Đơn" để bắt đầu!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentExpenses.length,
                        itemBuilder: (context, index) {
                          final item = _recentExpenses[index];
                          return ExpenseCard(
                            item: item,
                            onTap: () {
                              setState(() => _currentIndex = 1);
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 80), // Padding for FloatingActionButton
                  ],
                ),
              ),
            ),
    );
  }
}
