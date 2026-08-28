import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserSalaryPage extends StatefulWidget {
  const UserSalaryPage({super.key});

  @override
  State<UserSalaryPage> createState() => _UserSalaryPageState();
}

class _UserSalaryPageState extends State<UserSalaryPage> {
  DateTime _selectedMonth = DateTime.now();
  final _fmt = NumberFormat('#,###', 'vi');

  // Mock data for current user
  final Map<String, dynamic> _currentSalary = {
    'workingDays': 21,
    'totalDays': 22,
    'baseSalary': 15000000,
    'overtime': 8.5,
    'overtimeRate': 100000,
    'bonus': 500000,
    'transferred': true,
  };

  final List<Map<String, dynamic>> _salaryHistory = [
    {
      'month': 'Tháng 4/2025',
      'total': 16350000,
      'transferred': true,
    },
    {
      'month': 'Tháng 3/2025',
      'total': 15800000,
      'transferred': true,
    },
    {
      'month': 'Tháng 2/2025',
      'total': 14200000,
      'transferred': true,
    },
    {
      'month': 'Tháng 1/2025',
      'total': 16000000,
      'transferred': true,
    },
  ];

  int get _totalSalary {
    final base = (_currentSalary['baseSalary'] as int) *
        (_currentSalary['workingDays'] as int) ~/
        (_currentSalary['totalDays'] as int);
    final overtime = ((_currentSalary['overtime'] as double) *
            (_currentSalary['overtimeRate'] as int))
        .toInt();
    return base + overtime + (_currentSalary['bonus'] as int);
  }

  int get _basePaid =>
      (_currentSalary['baseSalary'] as int) *
      (_currentSalary['workingDays'] as int) ~/
      (_currentSalary['totalDays'] as int);

  int get _overtimePay =>
      ((_currentSalary['overtime'] as double) *
              (_currentSalary['overtimeRate'] as int))
          .toInt();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.light;
    final bgColor = isDark ? const Color(0xFFF5F7FA) : const Color(0xFF0D1117) ;
    const primary = Color(0xFF4361EE);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        forceMaterialTransparency: true,
        title: const Text(
          'Lương của tôi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Month Picker
          _buildMonthPicker(isDark),
          const SizedBox(height: 16),

          // Salary Hero Card
          _buildSalaryHeroCard(isDark, primary),
          const SizedBox(height: 20),

          // Salary Details
          Text(
            'Chi tiết lương',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.black87 : Colors.white ,
            ),
          ),
          const SizedBox(height: 12),
          _buildSalaryDetails(isDark, primary),
          const SizedBox(height: 20),

          // Salary History
          Text(
            'Lịch sử lương',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.black87 : Colors.white ,
            ),
          ),
          const SizedBox(height: 12),
          ..._salaryHistory.map((h) => _buildHistoryCard(h, isDark, primary)),
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
              color: isDark ? Colors.black87 : Colors.white ,
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

  Widget _buildSalaryHeroCard(bool isDark, Color primary) {
    final transferred = _currentSalary['transferred'] as bool;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4361EE), Color(0xFF7B5EA7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.4),
            blurRadius: 20,
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
              const Text(
                'Tổng lương tháng này',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: transferred
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: transferred ? Colors.greenAccent : Colors.orangeAccent,
                    width: 1,
                  ),
                ),
                child: Text(
                  transferred ? '✓ Đã nhận' : '⏳ Chưa nhận',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_fmt.format(_totalSalary)}đ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _heroStat(
                  'Ngày công',
                  '${_currentSalary['workingDays']}/${_currentSalary['totalDays']}'),
              const SizedBox(width: 24),
              _heroStat(
                  'Tăng ca', '${_currentSalary['overtime']}h'),
              const SizedBox(width: 24),
              _heroStat('Thưởng', '${_fmt.format(_currentSalary['bonus'] as int)}đ'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  Widget _buildSalaryDetails(bool isDark, Color primary) {
    final cardColor = isDark ? Colors.white : const Color(0xFF161B22) ;
    final workRatio = (_currentSalary['workingDays'] as int) /
        (_currentSalary['totalDays'] as int);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Working days progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ngày công',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.black87 : Colors.white ,
                ),
              ),
              Text(
                '${_currentSalary['workingDays']}/${_currentSalary['totalDays']} ngày',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: workRatio,
              minHeight: 8,
              backgroundColor: primary.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4361EE)),
            ),
          ),
          const SizedBox(height: 20),
          _detailRow('Lương cơ bản (theo công)', '${_fmt.format(_basePaid)}đ',
              isDark),
          _detailRow('Phụ cấp tăng ca (${_currentSalary['overtime']}h)',
              '${_fmt.format(_overtimePay)}đ', isDark),
          _detailRow('Thưởng thêm',
              '${_fmt.format(_currentSalary['bonus'] as int)}đ', isDark),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thực nhận',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${_fmt.format(_totalSalary)}đ',
                style: const TextStyle(
                  color: Color(0xFF4361EE),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ?  Colors.black54 : Colors.white60 ,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.black87 : Colors.white ,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
      Map<String, dynamic> history, bool isDark, Color primary) {
    final cardColor = isDark ?  Colors.white : const Color(0xFF161B22);
    final transferred = history['transferred'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.payments_outlined, color: primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history['month'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.black87 : Colors.white ,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  transferred ? 'Đã nhận' : 'Chưa nhận',
                  style: TextStyle(
                    fontSize: 12,
                    color: transferred ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_fmt.format(history['total'] as int)}đ',
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
