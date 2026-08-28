import 'dart:math' as math;

import 'package:attendee/auth/supabase_auth.dart';
import 'package:attendee/pages/settings.dart';
import 'package:attendee/services/api_service.dart';
import 'package:attendee/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../provider/profile_image_provider.dart';
import 'notification_page.dart';

class AdminHomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminHomePage({super.key, required this.user});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late final Map<String, dynamic> userInfo;
  String fullName = 'Name';
  DateTime _selectedDate = DateTime.now();

  // API-sourced summary data (replaces mock data)
  _AttendanceSummary? _apiSummary;
  bool _isLoadingReport = false;

  // ── Init ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    userInfo = widget.user;
    fullName = widget.user['name']?.toString().trim() ?? 'User';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final phone = widget.user['phone']?.toString().trim() ?? '';
      final email = widget.user['email']?.toString().trim() ?? '';
      final db = Provider.of<DatabaseHelperProvider>(context, listen: false);
      await db.updateUserField('full_name', fullName);
      if (phone.isNotEmpty && phone != 'null') await db.updateUserField('phone', phone);
      if (email.isNotEmpty) await db.updateUserField('email', email);
      await _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() => _isLoadingReport = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final result = await ApiService.getBaoCaoTong(date: dateStr);

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? {};

        final total    = (data['TongNhanVien']              as num?)?.toInt() ?? 0;
        final onTime   = (data['TongNhanVienDungGio']       as num?)?.toInt() ?? 0;
        final late     = (data['TongNhanVienDiMuon']        as num?)?.toInt() ?? 0;
        final halfDay  = (data['TongNhanVienLamNuaNgay']    as num?)?.toInt() ?? 0;
        final fullTime = (data['TongNhanVienLamToanThoiGian'] as num?)?.toInt() ?? 0;
        final absent   = (data['TongNhanVienVangMat']       as num?)?.toInt() ?? 0;
        final present  = total - absent;

        // Collect absent names from BaoCaoTheoKhuVuc
        final List<String> absentList = [];
        final khuVucs = data['BaoCaoTheoKhuVuc'];
        if (khuVucs is List) {
          for (final kv in khuVucs) {
            if (kv is Map) {
              final dsVang = kv['ds_vang'];
              if (dsVang is List) {
                absentList.addAll(dsVang.map((e) => e.toString()));
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _apiSummary = _AttendanceSummary(
              total: total,
              onTime: onTime,
              late: late,
              halfDay: halfDay,
              fullTime: fullTime,
              absent: absent,
              present: present,
              absentNames: absentList,
            );
          });
        }
      } else {
        String msg = result["message"]?.toString().toLowerCase() ?? "";
        if (msg.contains("invalid credential") ||
            msg.contains("token") ||
            msg.contains("expired")) {
          if (mounted) {
            await OauthHelper().signOutUser(context);
            CustomSnackbar.show(
              context: context,
              label: 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.',
            );
            Future.delayed(const Duration(milliseconds: 1000), () {
              Navigator.of(context).pushNamedAndRemoveUntil("/login", (route) => false);
            });
          }
          return;
        }
        if (mounted) {
          CustomSnackbar.show(
            context: context,
            label: 'Không thể tải báo cáo: ${result['message'] ?? ''}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context: context, label: 'Không thể tải dữ liệu: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingReport = false);
    }
  }

  _AttendanceSummary _buildSummary() {
    // Return API data if available; otherwise return empty summary
    return _apiSummary ??
        const _AttendanceSummary(
          total: 0, onTime: 0, late: 0,
          halfDay: 0, fullTime: 0, absent: 0,
          present: 0, absentNames: [],
        );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _fetchInitialData(); // Refresh report for new date
    }
  }

  String _formatDate(DateTime d) {
    const days = ['', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    return '${days[d.weekday]}, ngày ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.light;
    final profile = Provider.of<DatabaseHelperProvider>(context).profile;
    final summary = _buildSummary();
    final designation = (profile?['designation']?.toString().isNotEmpty == true)
        ? profile!['designation'] : 'Quản lý';

    final pageBg = isDark ? const Color(0xFFF5F7FA) : const Color(0xFF0D1117);
    final cardBg = isDark ? Colors.white : const Color(0xFF161B22);
    final border = isDark ? const Color(0xFFE5E7EB) : Colors.white.withOpacity(0.10);
    final txtPri = isDark ? const Color(0xFF111827) : Colors.white;
    final txtSec = isDark ? const Color(0xFF6B7280) : Colors.white60;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: _fetchInitialData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── TOP HEADER ──────────────────────────────────────
                _buildHeader(isDark, txtPri, txtSec, designation),
                const SizedBox(height: 14),

                // ── Loading indicator ───────────────────────────────
                if (_isLoadingReport) ...[
                  const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
                  const SizedBox(height: 14),
                ],

                // ── Summary cards ────────────────────────────────────
                _buildSummaryCards(summary, cardBg, border, isDark),
                const SizedBox(height: 14),

                // ── Detail table ─────────────────────────────────────
                _buildDetailTable(summary, cardBg, border, txtPri, txtSec, isDark),
                const SizedBox(height: 12),

                // ── Donut + Attendance (side by side) ───────────────
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildDonutCard(summary, cardBg, border, txtPri, isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildAttendanceCard(summary, cardBg, border, txtPri, txtSec, isDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────
  // Layout:
  //  [📋 Tiêu đề + ngày]          [🔔] [⚙] [Avatar]
  //  [Date picker]  [Làm mới]
  Widget _buildHeader(bool isDark, Color txtPri, Color txtSec, String designation) {
    final iconBg = isDark ? const Color(0xFFF3F4F6) : Colors.white.withOpacity(0.08);
    final iconColor = isDark ? const Color(0xFF374151) : Colors.white70;

    return Consumer<ProfileImageProvider>(
      builder: (_, profileProvider, __) {
        final imgProvider = profileProvider.cachedImageBytes != null
            ? MemoryImage(profileProvider.cachedImageBytes!) as ImageProvider
            : (profileProvider.imageUrl != null && profileProvider.imageUrl!.isNotEmpty
            ? NetworkImage(profileProvider.imageUrl!) as ImageProvider
            : const AssetImage('assets/images/avatar.png'));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Title + action icons
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Báo cáo chấm công',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: txtPri,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(_selectedDate),
                        style: TextStyle(fontSize: 12, color: txtSec),
                      ),
                    ],
                  ),
                ),

                // ── Action icons: Notification ──
                _iconButton(
                  icon: Icons.notifications_outlined,
                  bg: iconBg,
                  color: iconColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  ),
                ),
                const SizedBox(width: 8),

                // ── Action icons: Settings ──
                _iconButton(
                  icon: Icons.settings_outlined,
                  bg: iconBg,
                  color: iconColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettingPage(user: userInfo)),
                  ),
                ),
                const SizedBox(width: 8),

                // ── Avatar (tap → Settings) ──
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettingPage(user: userInfo)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2563EB),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: imgProvider,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Row 2: Subtitle + Date picker + Refresh
            Row(
              children: [
                // Name & role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(
                        '$fullName • $designation',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Date picker
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Color(0xFF2563EB)),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Refresh button
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: _fetchInitialData,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.refresh, size: 13),
                    label: const Text('Làm mới'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Icon button tròn dùng trong header
  Widget _iconButton({
    required IconData icon,
    required Color bg,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 19, color: color),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Summary cards ─────────────────────────────────────────────────
  Widget _buildSummaryCards(_AttendanceSummary s, Color cardBg, Color border, bool isDark) {
    final cards = [
      ('👥', 'Tổng NV',   '${s.total}',    'toàn hệ thống',   const Color(0xFF374151)),
      ('✅', 'Đúng giờ',  '${s.onTime}',   'buổi sáng',       const Color(0xFF16A34A)),
      ('🕐', 'Đi muộn',   '${s.late}',     'không có ca sáng',const Color(0xFFF59E0B)),
      ('🔵', 'Nửa ngày',  '${s.halfDay}',  'chỉ sáng/chiều',  const Color(0xFF2563EB)),
      ('⭐', 'Toàn thời gian',   '${s.fullTime}', 'đủ sáng + chiều', const Color(0xFFEAB308)),
      ('❌', 'Vắng mặt',  '${s.absent}',   'không chấm công', const Color(0xFFDC2626)),
    ];
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (icon, label, value, sub, color) = cards[i];
          return Container(
            width: 128,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(icon, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF4B5563) : Colors.white70),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const Spacer(),
                Text(value,
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800,
                        color: color, height: 1)),
                const SizedBox(height: 2),
                Text(sub,
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF9CA3AF) : Colors.white54),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Detail table ──────────────────────────────────────────────────
  Widget _buildDetailTable(_AttendanceSummary s, Color cardBg, Color border,
      Color txtPri, Color txtSec, bool isDark) {
    final updateTime = DateFormat('HH:mm:ss').format(DateTime.now());
    final cols = [
      ('Khu vực',   Colors.transparent),
      ('Tổng NV',   const Color(0xFF374151)),
      ('Toàn TG',   const Color(0xFF16A34A)),
      ('Nửa ngày',  const Color(0xFF2563EB)),
      ('Đi muộn',   const Color(0xFFF59E0B)),
      ('Vắng',      const Color(0xFFDC2626)),
    ];

    // Build rows from API BaoCaoTheoKhuVuc data if available, else use summary totals
    final List<List<String>> dataRows = [];
    final apiData = _apiSummary;
    if (apiData != null && apiData.total > 0) {
      dataRows.add([
        'Công ty',
        '${apiData.total}',
        '${apiData.fullTime}',
        '${apiData.halfDay}',
        '${apiData.late}',
        '${apiData.absent}',
      ]);
      dataRows.add([
        'Tổng cộng',
        '${apiData.total}',
        '${apiData.fullTime}',
        '${apiData.halfDay}',
        '${apiData.late}',
        '${apiData.absent}',
      ]);
    } else {
      dataRows.add(['Công ty',   '${s.total}', '${s.fullTime}', '${s.halfDay}', '${s.late}', '${s.absent}']);
      dataRows.add(['Tổng cộng', '${s.total}', '${s.fullTime}', '${s.halfDay}', '${s.late}', '${s.absent}']);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('Chi tiết theo khu vực',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: txtPri))),
            Text('Cập nhật: $updateTime',
                style: TextStyle(fontSize: 11, color: txtSec)),
          ]),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FlexColumnWidth(2.0),
                  1: FlexColumnWidth(1.0),
                  2: FlexColumnWidth(1.0),
                  3: FlexColumnWidth(1.2),
                  4: FlexColumnWidth(1.2),
                  5: FlexColumnWidth(0.9),
                },
                children: [
                  // Header
                  TableRow(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFFF3F4F6) : Colors.white.withOpacity(0.07),
                    ),
                    children: cols.map((c) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      child: Text(c.$1,
                          textAlign: c.$1 == 'Khu vực' ? TextAlign.left : TextAlign.center,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF374151) : Colors.white)),
                    )).toList(),
                  ),
                  // Data rows
                  ...dataRows.asMap().entries.map((entry) {
                    final isLast = entry.key == dataRows.length - 1;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: isLast
                            ? (isDark ? const Color(0xFFF9FAFB) : Colors.white.withOpacity(0.03))
                            : Colors.transparent,
                      ),
                      children: List.generate(entry.value.length, (i) {
                        final isLabel = i == 0;
                        final valColor = isLabel ? txtPri : cols[i].$2;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                          child: Text(entry.value[i],
                              textAlign: isLabel ? TextAlign.left : TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: (isLabel || isLast) ? FontWeight.w700 : FontWeight.w500,
                                color: valColor,
                              )),
                        );
                      }),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Absent list
          if (s.absentNames.isNotEmpty) ...[
            const Text('Vắng – Công ty:',
                style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            ...s.absentNames.map((name) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 3),
              child: Row(children: [
                const Icon(Icons.circle, size: 5, color: Color(0xFFB91C1C)),
                const SizedBox(width: 6),
                Text(name, style: TextStyle(fontSize: 13, color: txtPri)),
              ]),
            )),
          ] else
            Row(children: [
              const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF16A34A)),
              const SizedBox(width: 6),
              Text('Tất cả nhân viên đã chấm công',
                  style: TextStyle(fontSize: 12, color: txtSec)),
            ]),
        ],
      ),
    );
  }

  // ── Donut card ────────────────────────────────────────────────────
  Widget _buildDonutCard(_AttendanceSummary s, Color cardBg, Color border, Color txtPri, bool isDark) {
    final items = [
      ('Toàn TG',   s.fullTime, const Color(0xFF16A34A)),
      ('Nửa ngày',  s.halfDay,  const Color(0xFF2563EB)),
      ('Đi muộn',   s.late,     const Color(0xFFF59E0B)),
      ('Vắng mặt',  s.absent,   const Color(0xFFDC2626)),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phân bố hôm nay',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: txtPri)),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 110, height: 110,
              child: CustomPaint(
                painter: _DonutPainter(
                  values: items.map((e) => e.$2.toDouble()).toList(),
                  colors: items.map((e) => e.$3).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(children: [
              Container(width: 9, height: 9,
                  decoration: BoxDecoration(color: e.$3, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 7),
              Expanded(child: Text(e.$1, style: TextStyle(fontSize: 11, color: txtPri))),
              Text('${e.$2}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: txtPri)),
            ]),
          )),
        ],
      ),
    );
  }

  // ── Attendance rate card ──────────────────────────────────────────
  Widget _buildAttendanceCard(_AttendanceSummary s, Color cardBg, Color border,
      Color txtPri, Color txtSec, bool isDark) {
    final percent = s.total == 0 ? 0 : ((s.present / s.total) * 100).round();
    final progress = s.total == 0 ? 0.0 : s.present / s.total;
    final barColor = progress < 0.5 ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tỉ lệ có mặt',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: txtPri)),
          const SizedBox(height: 8),
          Text('hôm nay', style: TextStyle(fontSize: 11, color: txtSec)),
          const SizedBox(height: 4),
          Text('$percent%',
              style: TextStyle(
                  fontSize: 38, fontWeight: FontWeight.w800, color: txtPri, height: 1.1)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress, minHeight: 10,
              color: barColor,
              backgroundColor: isDark ? const Color(0xFFE5E7EB) : Colors.white.withOpacity(0.15),
            ),
          ),
          const SizedBox(height: 8),
          Text('${s.present}/${s.total} NV có mặt',
              style: TextStyle(fontSize: 12, color: txtSec)),
          const SizedBox(height: 14),
          _miniStat('Đúng giờ',  s.onTime,   const Color(0xFF16A34A), isDark),
          _miniStat('Đi muộn',   s.late,     const Color(0xFFF59E0B), isDark),
          _miniStat('Vắng mặt',  s.absent,   const Color(0xFFDC2626), isDark),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 11,
                color: isDark ? const Color(0xFF6B7280) : Colors.white60))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$value',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
      ]),
    );
  }
}

// ── Models ─────────────────────────────────────────────────────────────

class _AttendanceSummary {
  final int total, onTime, late, halfDay, fullTime, absent, present;
  final List<String> absentNames;
  const _AttendanceSummary({
    required this.total, required this.onTime, required this.late,
    required this.halfDay, required this.fullTime, required this.absent,
    required this.present, required this.absentNames,
  });
}

// ── Donut painter ───────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  const _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;
    final sw = r * 0.30;
    final rect = Rect.fromCircle(center: c, radius: r - sw / 2);
    final total = values.fold<double>(0, (s, v) => s + v);
    if (total == 0) {
      canvas.drawCircle(c, r - sw / 2,
          Paint()..style = PaintingStyle.stroke
            ..strokeWidth = sw
            ..color = const Color(0xFFDC2626));
      return;
    }
    var angle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweep = (values[i] / total) * 2 * math.pi;
      canvas.drawArc(rect, angle, sweep, false,
          Paint()..style = PaintingStyle.stroke
            ..strokeWidth = sw
            ..strokeCap = StrokeCap.butt
            ..color = colors[i]);
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.values.toString() != values.toString();
}