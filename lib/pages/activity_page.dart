import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  static const int _perPage = 20;

  String? _selectedFilter; // null = Tất cả
  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  /// Convert API record to display format
  Map<String, dynamic> _convertToDisplayFormat(Map<String, dynamic> record) {
    DateTime? timestamp;
    final timeStr = record['time']?.toString() ?? '';
    if (timeStr.isNotEmpty) {
      try {
        timestamp = DateTime.parse(timeStr).toLocal();
      } catch (_) {}
    }

    final lydodiemdanhho = record['lydodiemdanhho']?.toString() ?? '';
    final statusText = lydodiemdanhho.isNotEmpty ? lydodiemdanhho : 'Bình thường';

    final dateLabel = timestamp != null
        ? DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(timestamp)
        : '';

    // Classify based on time
    String title = 'Điểm danh';
    IconData icon = Icons.fingerprint;
    Color statusColor = const Color(0xFF667EEA);

    if (timestamp != null) {
      final hour = timestamp.hour;
      if (hour < 12) {
        title = 'Check-In sáng';
        icon = Icons.login;
        statusColor = const Color(0xFF10B981);
      } else if (hour >= 12 && hour < 14) {
        title = 'Check-In chiều';
        icon = Icons.login;
        statusColor = const Color(0xFF10B981);
      } else {
        title = 'Check-Out';
        icon = Icons.logout;
        statusColor = const Color(0xFF6366F1);
      }
    }

    return {
      'id': record['id'],
      'serial': record['serial'],
      'cbnv': record['cbnv'],
      'title': title,
      'icon': icon,
      'date': dateLabel,
      'rawDate': timestamp,
      'time': timestamp != null ? DateFormat('HH:mm:ss').format(timestamp) : '--:--',
      'status': statusText,
      'timestamp': timestamp ?? DateTime.now(),
      'statusColor': statusColor,
    };
  }

  Future<void> _loadAttendances({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _allRecords = [];
        _filteredRecords = [];
      });
    }

    if (!_hasMore && !refresh) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('user_id') ?? '';
      final userIdInt = int.tryParse(userIdStr);

      final result = await ApiService.getAttendanceHistory(
        userFilter: userIdInt,
        page: _currentPage,
        perPage: _perPage,
      );

      if (result['success'] == true) {
        final dataProvider = result['dataProvider'] as List? ?? [];
        _totalPages = result['pages'] ?? 1;

        if (dataProvider.isNotEmpty) {
          final newRecords = dataProvider
              .whereType<Map>()
              .map((e) => _convertToDisplayFormat(Map<String, dynamic>.from(e)))
              .toList();

          setState(() {
            _allRecords.addAll(newRecords);
            _applyFilter();
            _currentPage++;
            _hasMore = _currentPage <= _totalPages;
          });
        } else {
          setState(() => _hasMore = false);
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    if (_selectedFilter == null) {
      _filteredRecords = List.from(_allRecords);
    } else {
      _filteredRecords = _allRecords
          .where((e) => e['title'] == _selectedFilter)
          .toList();
    }

    // Sort by timestamp descending
    _filteredRecords.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
  }

  void _setFilter(String? filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Hôm nay';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Hôm qua';
    }
    return DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 350;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Get unique titles for filter chips
    final availableTitles = _allRecords.map((e) => e['title'] as String).toSet();

    // Group by date
    final Map<DateTime, List<Map<String, dynamic>>> groupedByDate = {};
    for (final record in _filteredRecords) {
      final date = DateTime(
        record['timestamp'].year,
        record['timestamp'].month,
        record['timestamp'].day,
      );
      groupedByDate.putIfAbsent(date, () => []).add(record);
    }

    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Lịch sử chấm công",
          style: TextStyle(letterSpacing: 1.1, wordSpacing: 1.1),
        ),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadAttendances(refresh: true),
        child: Column(
          children: [
            // Filter chips
            if (_allRecords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: "Tất cả",
                        isSelected: _selectedFilter == null,
                        onTap: () => _setFilter(null),
                      ),
                      if (availableTitles.contains('Check-In sáng')) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: "Check-In sáng",
                          icon: Icons.login,
                          color: const Color(0xFF10B981),
                          isSelected: _selectedFilter == "Check-In sáng",
                          onTap: () => _setFilter("Check-In sáng"),
                        ),
                      ],
                      if (availableTitles.contains('Check-In chiều')) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: "Check-In chiều",
                          icon: Icons.login,
                          color: const Color(0xFF10B981),
                          isSelected: _selectedFilter == "Check-In chiều",
                          onTap: () => _setFilter("Check-In chiều"),
                        ),
                      ],
                      if (availableTitles.contains('Check-Out')) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: "Check-Out",
                          icon: Icons.logout,
                          color: const Color(0xFF6366F1),
                          isSelected: _selectedFilter == "Check-Out",
                          onTap: () => _setFilter("Check-Out"),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Attendance list
            Expanded(
              child: _buildList(
                isDark,
                isSmallScreen,
                groupedByDate,
                sortedDates,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
      bool isDark,
      bool isSmallScreen,
      Map<DateTime, List<Map<String, dynamic>>> groupedByDate,
      List<DateTime> sortedDates,
      ) {
    if (_isLoading && _allRecords.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allRecords.isEmpty && !_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text('Chưa có dữ liệu chấm công.'),
        ),
      );
    }

    if (sortedDates.isEmpty && !_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text('Không tìm thấy dữ liệu phù hợp.'),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 100 &&
            !_isLoading &&
            _hasMore) {
          _loadAttendances();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: sortedDates.length + (_isLoading && _hasMore ? 1 : 0),
        itemBuilder: (context, dateIndex) {
          if (dateIndex == sortedDates.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final date = sortedDates[dateIndex];
          final eventsForDate = groupedByDate[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 12 : 20,
                  16,
                  12,
                  8,
                ),
                child: Text(
                  _formatDateHeader(date),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF667EEA),
                  ),
                ),
              ),

              // Events for this date
              ...eventsForDate.asMap().entries.map((entry) {
                final index = entry.key;
                final event = entry.value;
                final isLast = index == eventsForDate.length - 1;
                final statusColor = event['statusColor'] as Color;

                return Padding(
                  padding: EdgeInsets.only(
                    left: isSmallScreen ? 12 : 20,
                    right: isSmallScreen ? 12 : 20,
                    bottom: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline indicator
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 60,
                              color: isDark ? Colors.grey[700] : Colors.grey[300],
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Event card
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E2E)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: statusColor.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  event['icon'] as IconData? ?? Icons.fingerprint,
                                  color: statusColor,
                                  size: isSmallScreen ? 20 : 24,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event['title'] ?? 'Điểm danh',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'NV: ${event['cbnv'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Time and status
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    event['time'],
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      event['status'] ?? 'Bình thường',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? const Color(0xFF667EEA))
                : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? (color ?? const Color(0xFF667EEA)) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}