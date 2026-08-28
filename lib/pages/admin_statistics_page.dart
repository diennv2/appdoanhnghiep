import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({super.key});

  @override
  State<AdminStatisticsPage> createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDay = DateTime.now();
  DateTime _selectedMonth = DateTime.now();

  // Standard work start hour used to classify on-time vs late
  static const int _standardWorkStartHour = 8;

  // Daily tab state
  List<Map<String, dynamic>> _dailyAttendance = [];
  bool _isDailyLoading = false;
  String? _dailyError;

  // Monthly tab state
  List<Map<String, dynamic>> _monthlyEmployees = [];
  bool _isMonthlyLoading = false;
  String? _monthlyError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDailyData();
    _loadMonthlyData();
  }

  Future<void> _loadDailyData() async {
    if (!mounted) return;
    setState(() { _isDailyLoading = true; _dailyError = null; });
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
      final result = await ApiService.getAttendances(dateFilter: dateStr, page: 1);
      if (result['success'] == true) {
        final raw = (result['dataProvider'] as List).cast<Map<String, dynamic>>();
        // Group records by employee name
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final record in raw) {
          final cbnv = record['cbnv']?.toString() ?? '';
          if (cbnv.isEmpty) continue;
          grouped.putIfAbsent(cbnv, () => []).add(record);
        }
        final List<Map<String, dynamic>> mapped = [];
        for (final entry in grouped.entries) {
          final name = entry.key;
          final records = List<Map<String, dynamic>>.from(entry.value);
          // Sort records by time ascending
          records.sort((a, b) {
            final ta = DateTime.tryParse(a['time']?.toString() ?? '') ?? DateTime(0);
            final tb = DateTime.tryParse(b['time']?.toString() ?? '') ?? DateTime(0);
            return ta.compareTo(tb);
          });
          DateTime? checkInTime;
          String checkIn = '--';
          String checkOut = '--';
          try {
            final rawTime = records.first['time']?.toString() ?? '';
            if (rawTime.isNotEmpty) {
              checkInTime = DateTime.parse(rawTime).toLocal();
              checkIn = DateFormat('HH:mm').format(checkInTime);
            }
          } catch (_) {}
          if (records.length > 1) {
            try {
              final rawTime = records.last['time']?.toString() ?? '';
              if (rawTime.isNotEmpty) {
                checkOut = DateFormat('HH:mm').format(DateTime.parse(rawTime).toLocal());
              }
            } catch (_) {}
          }
          // Note: API only returns employees who scanned in; absent employees
          // are not included in the response so 'absent' count will be 0.
          String status = 'on_time';
          int deviation = 0;
          if (checkInTime != null) {
            final standardStart = DateTime(checkInTime.year, checkInTime.month,
                checkInTime.day, _standardWorkStartHour, 0);
            deviation = checkInTime.difference(standardStart).inMinutes;
            status = deviation > 0 ? 'late' : 'on_time';
          }
          mapped.add({
            'name': name,
            'checkIn': checkIn,
            'checkOut': checkOut,
            'status': status,
            'deviation': deviation,
            'lydodiemdanhho': records.first['lydodiemdanhho']?.toString() ?? '',
          });
        }
        if (mounted) setState(() { _dailyAttendance = mapped; _isDailyLoading = false; });
      } else {
        if (mounted) setState(() { _dailyAttendance = []; _isDailyLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() {
        _dailyAttendance = [];
        _isDailyLoading = false;
        _dailyError = 'Không thể tải dữ liệu. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _loadMonthlyData() async {
    if (!mounted) return;
    setState(() { _isMonthlyLoading = true; _monthlyError = null; });
    try {
      final result = await ApiService.getBangChamCong(
        thang: _selectedMonth.month,
        nam: _selectedMonth.year,
      );
      if (result['success'] == true) {
        final khuvucs = (result['khuvucs'] as List).cast<Map<String, dynamic>>();
        final List<Map<String, dynamic>> allEmployees = [];
        for (final kv in khuvucs) {
          final nhanviens = kv['nhanvien'];
          if (nhanviens is! List) continue;
          for (final nv in nhanviens) {
            if (nv is! Map) continue;
            final ngayRaw = nv['ngay'];
            final Map<int, String> days = {};
            if (ngayRaw is Map) {
              for (final e in ngayRaw.entries) {
                final day = int.tryParse(e.key.toString());
                final val = (e.value as num?)?.toDouble() ?? 0.0;
                if (day == null) continue;
                if (val >= 1.0) {
                  days[day] = 'P';
                } else if (val > 0.0) {
                  days[day] = 'L';
                } else {
                  days[day] = 'A';
                }
              }
            }
            allEmployees.add({
              'name': nv['hoten']?.toString() ?? '',
              'days': days,
              'tong': (nv['tong'] as num?)?.toDouble() ?? 0.0,
            });
          }
        }
        if (mounted) setState(() { _monthlyEmployees = allEmployees; _isMonthlyLoading = false; });
      } else {
        if (mounted) setState(() { _monthlyEmployees = []; _isMonthlyLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() {
        _monthlyEmployees = [];
        _isMonthlyLoading = false;
        _monthlyError = 'Không thể tải dữ liệu. Vui lòng thử lại.';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.light;
    final bgColor = isDark ? const Color(0xFFF5F7FA) : const Color(0xFF0D1117);
    const primary = Color(0xFF4361EE);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        forceMaterialTransparency: true,
        title: const Text('Thống kê & Báo cáo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor: isDark ? Colors.black54 : Colors.white54,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Theo ngày'), Tab(text: 'Theo tháng')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyTab(isDark, primary),
          _buildMonthlyTab(isDark, primary),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  DAILY TAB
  // ════════════════════════════════════════════════════════════════
  Widget _buildDailyTab(bool isDark, Color primary) {
    if (_isDailyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_dailyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(_dailyError!,
              style: TextStyle(color: Colors.red.shade400), textAlign: TextAlign.center),
        ),
      );
    }

    final onTime = _dailyAttendance.where((e) => e['status'] == 'on_time').length;
    final late   = _dailyAttendance.where((e) => e['status'] == 'late').length;
    final absent = _dailyAttendance.where((e) => e['status'] == 'absent').length;
    final total  = _dailyAttendance.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDayPicker(isDark, primary),
        const SizedBox(height: 16),
        // _buildStatCards(isDark, total, onTime, late, absent, primary),
        // const SizedBox(height: 20),
        Text('Chi tiết điểm danh',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: isDark ? Colors.black87 : Colors.white)),
        const SizedBox(height: 12),
        if (_dailyAttendance.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Không có dữ liệu chấm công',
                  style: TextStyle(color: isDark ? Colors.black54 : Colors.white54)),
            ),
          )
        else
          ..._dailyAttendance.map((e) => _buildAttendanceCard(e, isDark, primary)),
      ],
    );
  }

  Widget _buildDayPicker(bool isDark, Color primary) {
    final cardColor = isDark ? Colors.white : const Color(0xFF161B22);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Icon(Icons.calendar_today_outlined, color: primary, size: 20),
        const SizedBox(width: 10),
        Text(DateFormat('dd/MM/yyyy').format(_selectedDay),
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                color: isDark ? Colors.black87 : Colors.white)),
        const Spacer(),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context, initialDate: _selectedDay,
              firstDate: DateTime(2020), lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => _selectedDay = picked);
              _loadDailyData();
            }
          },
          child: Text('Chọn ngày', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildStatCards(bool isDark, int total, int onTime, int late, int absent, Color primary) {
    return Row(children: [
      Expanded(child: _statCard('Tổng NV',   total.toString(),  Icons.people_alt_outlined,  primary,       isDark)),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Đúng giờ',  onTime.toString(), Icons.check_circle_outline,  Colors.green,  isDark)),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Đi muộn',   late.toString(),   Icons.schedule_outlined,     Colors.orange, isDark)),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Vắng mặt',  absent.toString(), Icons.cancel_outlined,       Colors.red,    isDark)),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isDark) {
    final cardColor = isDark ? Colors.white : const Color(0xFF161B22);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.black54 : Colors.white54),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> data, bool isDark, Color primary) {
    final cardColor = isDark ? Colors.white : const Color(0xFF161B22);
    final status = data['status'] as String;
    Color statusColor; String statusLabel; IconData statusIcon;
    switch (status) {
      case 'on_time': statusColor = Colors.green;  statusLabel = 'Đúng giờ'; statusIcon = Icons.check_circle_outline; break;
      case 'late':    statusColor = Colors.orange; statusLabel = 'Đi muộn';  statusIcon = Icons.schedule_outlined;     break;
      default:        statusColor = Colors.red;    statusLabel = 'Vắng mặt'; statusIcon = Icons.cancel_outlined;
    }
    final deviation = data['deviation'] as int;
    final deviationText = status == 'absent' ? '' :
    deviation == 0 ? 'Đúng giờ' : deviation > 0 ? '+$deviation phút' : '$deviation phút';
    final name = data['name'] as String;
    final proxyNote = data['lydodiemdanhho']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20, backgroundColor: primary.withOpacity(0.12),
          child: Text(name.isNotEmpty ? name.substring(0, 1) : '?',
              style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(name,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                      color: isDark ? Colors.black87 : Colors.white)),
            ),
            if (proxyNote.isNotEmpty)
              Semantics(
                label: 'Điểm danh hộ: $proxyNote',
                child: Tooltip(
                  message: proxyNote,
                  child: Icon(Icons.person_off_outlined, size: 14, color: Colors.orange),
                ),
              ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.login_outlined,  size: 13, color: isDark ? Colors.black54 : Colors.white54),
            const SizedBox(width: 4),
            Text(data['checkIn']  as String, style: TextStyle(fontSize: 12, color: isDark ? Colors.black54 : Colors.white54)),
            const SizedBox(width: 12),
            Icon(Icons.logout_outlined, size: 13, color: isDark ? Colors.black54 : Colors.white54),
            const SizedBox(width: 4),
            Text(data['checkOut'] as String, style: TextStyle(fontSize: 12, color: isDark ? Colors.black54 : Colors.white54)),
            if (deviationText.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(deviationText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: deviation > 0 ? Colors.orange : deviation < 0 ? Colors.blue : Colors.green)),
            ],
          ]),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(statusIcon, color: statusColor, size: 13),
            const SizedBox(width: 4),
            Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  MONTHLY TAB – BẢNG CHẤM CÔNG
  // ════════════════════════════════════════════════════════════════
  Widget _buildMonthlyTab(bool isDark, Color primary) {
    final cardBg   = isDark ? Colors.white : const Color(0xFF161B22);
    final txtPri   = isDark ? const Color(0xFF111827) : Colors.white;
    final txtSec   = isDark ? const Color(0xFF6B7280) : Colors.white60;
    final border   = isDark ? const Color(0xFFE5E7EB) : Colors.white.withOpacity(0.10);

    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final employees = _monthlyEmployees;

    // Tính tổng
    int totalP = 0, totalL = 0, totalA = 0;
    for (final emp in employees) {
      final days = emp['days'] as Map<int, String>;
      totalP += days.values.where((v) => v == 'P').length;
      totalL += days.values.where((v) => v == 'L').length;
      totalA += days.values.where((v) => v == 'A').length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Month navigator ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cardBg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(
              icon: Icon(Icons.chevron_left_rounded, color: txtPri),
              onPressed: () {
                setState(() =>
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
                _loadMonthlyData();
              },
            ),
            Column(children: [
              Text('BẢNG CHẤM CÔNG',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                      color: txtPri, letterSpacing: 1)),
              const SizedBox(height: 2),
              Text('Tháng ${_selectedMonth.month} năm ${_selectedMonth.year}',
                  style: TextStyle(fontSize: 12, color: txtSec)),
            ]),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded, color: txtPri),
              onPressed: () {
                final now = DateTime.now();
                if (_selectedMonth.isBefore(DateTime(now.year, now.month))) {
                  setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
                  _loadMonthlyData();
                }
              },
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // ── Summary chips ──────────────────────────────────────────
        Row(children: [
          _summaryChip(Icons.people_outline,      '${employees.length}', 'Nhân viên', const Color(0xFF4361EE), cardBg, border),
          const SizedBox(width: 8),
          _summaryChip(Icons.check_circle_outline, '$totalP', 'Có mặt',   const Color(0xFF16A34A), cardBg, border),
          const SizedBox(width: 8),
          _summaryChip(Icons.schedule_outlined,    '$totalL', 'Đi muộn',  const Color(0xFFF59E0B), cardBg, border),
          const SizedBox(width: 8),
          _summaryChip(Icons.cancel_outlined,      '$totalA', 'Vắng mặt', const Color(0xFFDC2626), cardBg, border),
        ]),
        const SizedBox(height: 16),

        // ── Attendance grid ────────────────────────────────────────
        Text('Bảng chấm công chi tiết',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: txtPri)),
        const SizedBox(height: 10),
        if (_isMonthlyLoading)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(),
          ))
        else if (_monthlyError != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(_monthlyError!,
                  style: TextStyle(color: Colors.red.shade400),
                  textAlign: TextAlign.center),
            ),
          )
        else if (employees.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text('Không có dữ liệu chấm công',
                  style: TextStyle(color: isDark ? Colors.black54 : Colors.white54)),
            ),
          )
        else
          _buildAttendanceGrid(
            isDark: isDark,
            daysInMonth: daysInMonth,
            employees: employees,
            cardBg: cardBg,
            border: border,
            txtPri: txtPri,
            txtSec: txtSec,
          ),
        const SizedBox(height: 16),

        // ── Legend ─────────────────────────────────────────────────
        _buildLegend(isDark, cardBg, border, txtPri),
      ]),
    );
  }

  Widget _summaryChip(IconData icon, String value, String label, Color color,
      Color cardBg, Color border) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: cardBg, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, height: 1)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  // ── Attendance grid (horizontal scroll) ───────────────────────────
  Widget _buildAttendanceGrid({
    required bool isDark,
    required int daysInMonth,
    required List<Map<String, dynamic>> employees,
    required Color cardBg,
    required Color border,
    required Color txtPri,
    required Color txtSec,
  }) {
    // Colors
    final headerBg    = isDark ? const Color(0xFF1E3A5F) : const Color(0xFF1E3A5F);
    const weekendBg   = Color(0xFFB8860B); // gold like the image
    final rowEvenBg   = isDark ? Colors.white : const Color(0xFF161B22);
    final rowOddBg    = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF1A2030);
    const cellW       = 28.0;
    const nameW       = 180.0;
    const sttW        = 36.0;
    const totalW      = 46.0;
    const rowH        = 36.0;
    const headerH     = 52.0;

    // Day info
    final List<int> days = List.generate(daysInMonth, (i) => i + 1);
    bool isWeekend(int day) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    }
    String dayLabel(int day) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      const short = ['T2','T3','T4','T5','T6','T7','CN'];
      return short[date.weekday - 1];
    }

    // Status cell
    Widget statusCell(String? status, Color rowBg) {
      if (status == null || status.isEmpty) {
        return Container(width: cellW, height: rowH, color: rowBg);
      }
      Color bg; String text; Color txtColor;
      switch (status) {
        case 'P':
          bg = const Color(0xFF16A34A).withOpacity(0.15);
          text = 'P'; txtColor = const Color(0xFF16A34A); break;
        case 'L':
          bg = const Color(0xFFF59E0B).withOpacity(0.15);
          text = 'M'; txtColor = const Color(0xFFF59E0B); break;
        case 'A':
          bg = const Color(0xFFDC2626).withOpacity(0.15);
          text = 'V'; txtColor = const Color(0xFFDC2626); break;
        default:
          bg = rowBg; text = ''; txtColor = Colors.transparent;
      }
      return Container(
        width: cellW, height: rowH,
        color: bg,
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: txtColor)),
      );
    }

    // Build full table widget
    return Container(
      decoration: BoxDecoration(
        color: cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────
              SizedBox(
                height: headerH,
                child: Row(children: [
                  // STT
                  Container(
                    width: sttW, height: headerH,
                    color: headerBg,
                    alignment: Alignment.center,
                    child: const Text('STT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  _vDivider(headerH),
                  // Tên
                  Container(
                    width: nameW, height: headerH,
                    color: headerBg,
                    alignment: Alignment.center,
                    child: const Text('Họ và Tên', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  _vDivider(headerH),
                  // Day columns
                  ...days.map((d) {
                    final weekend = isWeekend(d);
                    return Row(children: [
                      Container(
                        width: cellW, height: headerH,
                        color: weekend ? weekendBg : headerBg,
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('$d',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          Text(dayLabel(d),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 9, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                      _vDivider(headerH),
                    ]);
                  }),
                  // Tổng
                  Container(
                    width: totalW, height: headerH,
                    color: headerBg,
                    alignment: Alignment.center,
                    child: const Text('TỔNG', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),

              // ── Divider ─────────────────────────────────────────
              Container(height: 1, color: border),

              // ── Employee rows ────────────────────────────────────
              ...employees.asMap().entries.map((entry) {
                final i = entry.key;
                final emp = entry.value;
                final empDays = emp['days'] as Map<int, String>;
                final rowBg = i.isEven ? rowEvenBg : rowOddBg;
                final tong = (emp['tong'] as double?) ?? 0.0;
                final tongStr = tong == tong.truncateToDouble()
                    ? tong.toInt().toString()
                    : tong.toStringAsFixed(1);

                return Column(children: [
                  SizedBox(
                    height: rowH,
                    child: Row(children: [
                      // STT
                      Container(
                        width: sttW, height: rowH, color: rowBg,
                        alignment: Alignment.center,
                        child: Text('${i + 1}',
                            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF6B7280) : Colors.white60)),
                      ),
                      _vDivider(rowH),
                      // Name
                      Container(
                        width: nameW, height: rowH, color: rowBg,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.centerLeft,
                        child: Text(emp['name'] as String,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF111827) : Colors.white),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      _vDivider(rowH),
                      // Day cells
                      ...days.map((d) {
                        final weekend = isWeekend(d);
                        final status = empDays[d];
                        return Row(children: [
                          weekend
                              ? Container(
                            width: cellW, height: rowH,
                            color: weekendBg.withOpacity(0.18),
                          )
                              : statusCell(status, rowBg),
                          _vDivider(rowH),
                        ]);
                      }),
                      // Tổng
                      Container(
                        width: totalW, height: rowH, color: rowBg,
                        alignment: Alignment.center,
                        child: Text(tongStr,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: Color(0xFF16A34A))),
                      ),
                    ]),
                  ),
                  Container(height: 1, color: border.withOpacity(0.5)),
                ]);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider(double height) {
    return Container(
      width: 1, height: height,
      color: const Color(0xFFE5E7EB).withOpacity(0.4),
    );
  }

  // ── Legend ────────────────────────────────────────────────────────
  Widget _buildLegend(bool isDark, Color cardBg, Color border, Color txtPri) {
    final items = [
      ('P', const Color(0xFF16A34A), 'Có mặt đúng giờ'),
      ('M', const Color(0xFFF59E0B), 'Đi muộn'),
      ('V', const Color(0xFFDC2626), 'Vắng mặt'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ...items.map((e) => Row(children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                  color: e.$2.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4)),
              alignment: Alignment.center,
              child: Text(e.$1, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: e.$2)),
            ),
            const SizedBox(width: 6),
            Text(e.$3, style: TextStyle(fontSize: 11, color: txtPri)),
          ])),
        ],
      ),
    );
  }
}