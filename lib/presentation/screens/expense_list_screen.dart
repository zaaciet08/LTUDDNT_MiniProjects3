import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/date_format.dart';
import '../../models/expense_category.dart';
import '../../models/expense_item.dart';
import '../widgets/expense_card.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<ExpenseItem> _allExpenses = [];
  List<ExpenseItem> _filteredExpenses = [];
  String _selectedCategory = 'Tất cả';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    final items = await DatabaseHelper.instance.getAllExpenses();
    if (mounted) {
      setState(() {
        _allExpenses = items;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    _filteredExpenses = _allExpenses.where((item) {
      final matchesCategory =
          _selectedCategory == 'Tất cả' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.merchant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.rawOcrText?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _deleteItem(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    _loadExpenses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa hóa đơn khỏi sổ quỹ'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showExpenseDetails(ExpenseItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.categoryType.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.categoryType.icon, color: item.categoryType.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.merchant,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          item.category,
                          style: TextStyle(fontSize: 12, color: item.categoryType.color, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyHelper.format(item.amount),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildDetailRow(Icons.calendar_today, 'Ngày hóa đơn', DateHelper.formatDate(item.date)),
              _buildDetailRow(Icons.access_time, 'Thời gian quét', DateHelper.formatDateTime(item.createdAt)),
              if (item.rawOcrText != null && item.rawOcrText!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Văn bản OCR nhận diện:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.rawOcrText!,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (item.id != null) _deleteItem(item.id!);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Xóa hóa đơn này', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTotal = _filteredExpenses.fold<double>(0.0, (prev, e) => prev + e.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Lịch Sử Hóa Đơn & Sổ Quỹ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _applyFilter();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm cửa hàng, nội dung hóa đơn...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả'),
                      ...ExpenseCategoryType.values.map((c) => _buildFilterChip(c.label)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Total Bar for Current Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF1F5F9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredExpenses.length} hóa đơn',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Tổng: ${CurrencyHelper.format(filteredTotal)}',
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Expense List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Không tìm thấy hóa đơn nào',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadExpenses,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          itemCount: _filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final item = _filteredExpenses[index];
                            return ExpenseCard(
                              item: item,
                              onTap: () => _showExpenseDetails(item),
                              onDelete: () {
                                if (item.id != null) _deleteItem(item.id!);
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
          ),
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = label;
            _applyFilter();
          });
        },
      ),
    );
  }
}
