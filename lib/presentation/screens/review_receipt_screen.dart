import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/date_format.dart';
import '../../models/expense_category.dart';
import '../../models/expense_item.dart';
import '../../services/receipt_parser.dart';

class ReviewReceiptScreen extends StatefulWidget {
  final String imagePath;
  final ParsedReceiptData parsedData;

  const ReviewReceiptScreen({
    super.key,
    required this.imagePath,
    required this.parsedData,
  });

  @override
  State<ReviewReceiptScreen> createState() => _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends State<ReviewReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.parsedData.merchant);
    _amountController = TextEditingController(
      text: widget.parsedData.totalAmount > 0
          ? widget.parsedData.totalAmount.round().toString()
          : '',
    );
    _selectedDate = widget.parsedData.date;
    _selectedCategory = widget.parsedData.suggestedCategory;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'CHỌN NGÀY HÓA ĐƠN',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[,.\s]'), '')) ?? 0.0;
      final expense = ExpenseItem(
        merchant: _merchantController.text.trim(),
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        imagePath: widget.imagePath,
        rawOcrText: widget.parsedData.rawText,
      );

      await DatabaseHelper.instance.insertExpense(expense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu hóa đơn thành công!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Pop back to home with refresh trigger
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu hóa đơn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildImagePreview() {
    if (widget.imagePath.isEmpty) {
      return Container(
        color: const Color(0xFFEEF2F6),
        child: const Center(
          child: Icon(Icons.receipt_long, size: 64, color: Color(0xFF64748B)),
        ),
      );
    }

    if (kIsWeb) {
      if (widget.imagePath.startsWith('http') || widget.imagePath.startsWith('blob:') || widget.imagePath.startsWith('data:')) {
        return Image.network(
          widget.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFEEF2F6),
            child: const Center(
              child: Icon(Icons.receipt_long, size: 64, color: Color(0xFF64748B)),
            ),
          ),
        );
      }
      return Container(
        color: const Color(0xFFEEF2F6),
        child: const Center(
          child: Icon(Icons.receipt_long, size: 64, color: Color(0xFF64748B)),
        ),
      );
    }

    try {
      final file = File(widget.imagePath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    } catch (_) {}

    return Container(
      color: const Color(0xFFEEF2F6),
      child: const Center(
        child: Icon(Icons.receipt_long, size: 64, color: Color(0xFF64748B)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Xác Nhận Hóa Đơn',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Receipt Image Preview with OCR Badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _buildImagePreview(),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'ML Kit OCR Đã bóc tách',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Form Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    // Merchant Field
                    const Text(
                      'TÊN CỬA HÀNG / ĐƠN VỊ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _merchantController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.storefront, color: Color(0xFF3B82F6)),
                        hintText: 'Nhà sách, Quán cafe, Siêu thị...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tên cửa hàng' : null,
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    const Text(
                      'TỔNG TIỀN (VNĐ)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF10B981)),
                        suffixText: '₫',
                        hintText: 'Ví dụ: 150000',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số tiền';
                        final num = double.tryParse(val.replaceAll(RegExp(r'[,.\s]'), ''));
                        if (num == null || num <= 0) return 'Số tiền không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Picker Tile
                    const Text(
                      'NGÀY GIAO DỊCH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20, color: Color(0xFF6366F1)),
                            const SizedBox(width: 12),
                            Text(
                              DateHelper.formatDate(_selectedDate),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Selection Chips
                    const Text(
                      'DANH MỤC CHI TIÊU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ExpenseCategoryType.values.map((cat) {
                        final isSelected = _selectedCategory == cat.label;
                        return ChoiceChip(
                          avatar: Icon(
                            cat.icon,
                            size: 16,
                            color: isSelected ? Colors.white : cat.color,
                          ),
                          label: Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: cat.color,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat.label);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Expandable Raw OCR Text viewer
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ExpansionTile(
                  title: const Text(
                    'Xem văn bản gốc OCR (Raw OCR Text)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                  leading: const Icon(Icons.description_outlined, color: Color(0xFF64748B), size: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.parsedData.rawText.isNotEmpty
                              ? widget.parsedData.rawText
                              : '(Không có văn bản nào được nhận diện)',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isSaving ? 'Đang lưu...' : 'LƯU HÓA ĐƠN VÀO SỔ QUỸ',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
