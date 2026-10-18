import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/currency_format.dart';
import '../widgets/custom_donut_chart.dart';
import '../widgets/custom_bar_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  double _totalAmount = 0.0;
  Map<String, double> _categoryTotals = {};
  Map<DateTime, double> _dailyTotals = {};
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    final total = await DatabaseHelper.instance.getTotalAmount();
    final categories = await DatabaseHelper.instance.getCategoryTotals();
    final daily = await DatabaseHelper.instance.getLast7DaysTotals();
    final all = await DatabaseHelper.instance.getAllExpenses();

    if (mounted) {
      setState(() {
        _totalAmount = total;
        _categoryTotals = categories;
        _dailyTotals = daily;
        _totalCount = all.length;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Find top category
    String topCategory = 'Chưa có';
    double topAmount = 0;
    _categoryTotals.forEach((k, v) {
      if (v > topAmount) {
        topAmount = v;
        topCategory = k;
      }
    });

    final avgPerReceipt = _totalCount > 0 ? _totalAmount / _totalCount : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Báo Cáo & Biểu Đồ Canvas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Metric Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Tổng Chi Tiêu',
                            value: CurrencyHelper.format(_totalAmount),
                            icon: Icons.account_balance_wallet,
                            iconColor: const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Trung Bình / Đơn',
                            value: CurrencyHelper.format(avgPerReceipt),
                            icon: Icons.analytics_outlined,
                            iconColor: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      title: 'Khoản Chi Lớn Nhất',
                      value: '$topCategory (${CurrencyHelper.format(topAmount)})',
                      icon: Icons.trending_up,
                      iconColor: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 1: CUSTOM CANVAS DONUT CHART
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.pie_chart, color: Color(0xFF6366F1), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Phân Bổ Chi Tiêu Theo Danh Mục',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Vẽ bằng Flutter CustomPainter (Canvas)',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 20),
                          CustomDonutChart(
                            categoryTotals: _categoryTotals,
                            totalAmount: _totalAmount,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 2: CUSTOM CANVAS BAR CHART
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bar_chart, color: Color(0xFF0EA5E9), size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Chi Tiêu 7 Ngày Gần Nhất',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Vẽ trực tiếp trên Canvas với tỷ lệ động',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 20),
                          CustomBarChart(
                            dailyTotals: _dailyTotals,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
