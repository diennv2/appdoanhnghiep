import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminSalaryPage extends StatefulWidget {
  const AdminSalaryPage({super.key});

  @override
  State<AdminSalaryPage> createState() => _AdminSalaryPageState();
}

class _AdminSalaryPageState extends State<AdminSalaryPage> {
  DateTime _selectedMonth = DateTime.now();
  String _selectedFilter = 'all'; // all, paid, unpaid

  final _fmt = NumberFormat('#,###', 'vi');

  final List<Map<String, dynamic>> _employees = [
    {
      'name': 'Nguyễn Văn An',
      'designation': 'Kỹ sư phần mềm',
      'workingDays': 22,
      'totalDays': 22,
      'overtime': 8.5,
      'baseSalary': 15000000,
      'overtimeRate': 100000,
      'bonus': 500000,
      'transferred': true,
    },
    {
      'name': 'Trần Thị Bình',
      'designation': 'Thiết kế UI/UX',
      'workingDays': 20,
      'totalDays': 22,
      'overtime': 4.0,
      'baseSalary': 12000000,
      'overtimeRate': 90000,
      'bonus': 0,
      'transferred': false,
    },
    {
      'name': 'Lê Văn Cường',
      'designation': 'Backend Developer',
      'workingDays': 21,
      'totalDays': 22,
      'overtime': 12.0,
      'baseSalary': 18000000,
      'overtimeRate': 120000,
      'bonus': 1000000,
      'transferred': true,
    },
    {
      'name': 'Phạm Thị Dung',
      'designation': 'Kiểm thử phần mềm',
      'workingDays': 18,
      'totalDays': 22,
      'overtime': 0.0,
      'baseSalary': 10000000,
      'overtimeRate': 80000,
      'bonus': 0,
      'transferred': false,
    },
    {
      'name': 'Hoàng Văn Em',
      'designation': 'Quản lý dự án',
      'workingDays': 22,
      'totalDays': 22,
      'overtime': 6.0,
      'baseSalary': 20000000,
      'overtimeRate': 150000,
      'bonus': 2000000,
      'transferred': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredEmployees {
    if (_selectedFilter == 'paid') {
      return _employees.where((e) => e['transferred'] == true).toList();
    } else if (_selectedFilter == 'unpaid') {
      return _employees.where((e) => e['transferred'] == false).toList();
    }
    return _employees;
  }

  int _calcSalary(Map<String, dynamic> e) {
    final base = (e['baseSalary'] as int) *
        (e['workingDays'] as int) ~/
        (e['totalDays'] as int);
    final overtime =
        ((e['overtime'] as double) * (e['overtimeRate'] as int)).toInt();
    final bonus = e['bonus'] as int;
    return base + overtime + bonus;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.light;
    final bgColor = isDark ? const Color(0xFFF5F7FA) : const Color(0xFF0D1117);
    const primary = Color(0xFF4361EE);

    final transferred = _employees.where((e) => e['transferred'] == true).length;
    final total = _employees.length;
    final totalPayout = _employees.fold<int>(0, (sum, e) => sum + _calcSalary(e));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        forceMaterialTransparency: true,
        title: const Text(
          'Quản lý lương',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // Month Picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildMonthPicker(isDark),
          ),

          // Summary Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSummaryBanner(
                isDark, transferred, total, totalPayout, primary),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterChips(isDark, primary),
          ),
          const SizedBox(height: 8),

          // Employee List
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredEmployees.length,
              itemBuilder: (context, index) {
                return _buildEmployeeTile(
                    _filteredEmployees[index], isDark, primary);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPicker(bool isDark) {
    final cardColor = isDark ? Colors.white : const Color(0xFF161B22) ;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          Text(
            'Tháng ${_selectedMonth.month}/${_selectedMonth.year}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.black87  : Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              final now = DateTime.now();
              if (_selectedMonth.year < now.year ||
                  (_selectedMonth.year == now.year &&
                      _selectedMonth.month < now.month)) {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month + 1,
                  );
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner(bool isDark, int transferred, int total,
      int totalPayout, Color primary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4361EE), Color(0xFF7B5EA7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(
              'Đã chuyển', '$transferred/$total', Icons.check_circle_outline),
          _verticalDivider(),
          _summaryItem(
              'Chưa chuyển',
              '${total - transferred}',
              Icons.pending_outlined),
          _verticalDivider(),
          _summaryItem('Tổng chi', '${_fmt.format(totalPayout)}đ',
              Icons.payments_outlined),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 50, color: Colors.white24);
  }

  Widget _buildFilterChips(bool isDark, Color primary) {
    return Row(
      children: [
        _filterChip('Tất cả', 'all', isDark, primary),
        const SizedBox(width: 8),
        _filterChip('Đã chuyển', 'paid', isDark, primary),
        const SizedBox(width: 8),
        _filterChip('Chưa chuyển', 'unpaid', isDark, primary),
      ],
    );
  }

  Widget _filterChip(String label, String value, bool isDark, Color primary) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary : (isDark ?  Colors.white : const Color(0xFF161B22)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ?  Colors.black54 : Colors.white70 ),
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeTile(
      Map<String, dynamic> employee, bool isDark, Color primary) {
    final cardColor = isDark ? Colors.white : const Color(0xFF161B22);
    final transferred = employee['transferred'] as bool;
    final totalSalary = _calcSalary(employee);
    final basePaid = (employee['baseSalary'] as int) *
        (employee['workingDays'] as int) ~/
        (employee['totalDays'] as int);
    final overtimePay =
        ((employee['overtime'] as double) * (employee['overtimeRate'] as int))
            .toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        leading: CircleAvatar(
          backgroundColor: primary.withOpacity(0.12),
          child: Text(
            (employee['name'] as String).substring(0, 1),
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          employee['name'] as String,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.black87 : Colors.white,
          ),
        ),
        subtitle: Text(
          employee['designation'] as String,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.black54 :  Colors.white54,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: transferred
                    ? Colors.green.withOpacity(0.12)
                    : Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transferred ? 'Đã chuyển' : 'Chưa chuyển',
                style: TextStyle(
                  color: transferred ? Colors.green : Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_fmt.format(totalSalary)}đ',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          _salaryRow('Ngày công', '${employee['workingDays']}/${employee['totalDays']} ngày', isDark),
          _salaryRow('Giờ tăng ca', '${employee['overtime']} giờ', isDark),
          _salaryRow(
              'Lương cơ bản (theo công)', '${_fmt.format(basePaid)}đ', isDark),
          _salaryRow('Phụ cấp tăng ca', '${_fmt.format(overtimePay)}đ', isDark),
          _salaryRow('Thưởng thêm', '${_fmt.format(employee['bonus'] as int)}đ', isDark),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng lương',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark ? Colors.black87 : Colors.white,
                ),
              ),
              Text(
                '${_fmt.format(totalSalary)}đ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF4361EE),
                ),
              ),
            ],
          ),
          if (!transferred) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    final idx = _employees.indexOf(employee);
                    if (idx != -1) {
                      _employees[idx]['transferred'] = true;
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4361EE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text(
                  'Xác nhận đã chuyển lương',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _salaryRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ?  Colors.black54 : Colors.white60,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ?  Colors.black87 : Colors.white ,
            ),
          ),
        ],
      ),
    );
  }
}
