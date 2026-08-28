import 'package:app_links/app_links.dart';
import 'package:app_settings/app_settings.dart';
import 'package:attendee/database/database_helper.dart';
import 'package:attendee/widgets/custom_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamMemberPage extends StatefulWidget {
  const TeamMemberPage({super.key});

  @override
  _TeamMemberPageState createState() => _TeamMemberPageState();
}

class _TeamMemberPageState extends State<TeamMemberPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> teamMembers = [];
  List<Map<String, dynamic>> searchMember = [];
  Map<String, dynamic> memberAttendance = {};

  Future<void> _makePhoneCall(String phoneNumber) async {
    await FlutterPhoneDirectCaller.callNumber(phoneNumber);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<DatabaseHelperProvider>(context, listen: false);
      await provider.fetchTeamMemberProfile();
      final data = provider.teamMemberList ?? [];
      final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc());

      Map<String, dynamic> attendanceMap = {};
      await Future.forEach(data, (member) async {
        await provider.fetchUserAttendanceById(todayDate, member['id']);
        attendanceMap[member['id']] = provider.todayStatus;
      });

      setState(() {
        teamMembers = data;
        searchMember = List.from(data);
        memberAttendance = attendanceMap;
        print("Member Attendance list : $memberAttendance");
      });

      _searchController.addListener(_filterMembers);
    });
  }

  void _filterMembers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      searchMember = teamMembers.where((member) {
        final name = (member['full_name']?.toString() ?? '').toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
        forceMaterialTransparency: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.black : Colors.white ),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: isDark ? Colors.black54  : Colors.white54),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.black54  : Colors.white54),
                filled: true,
                fillColor: isDark ? Colors.white  : Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: searchMember.isEmpty
                ? const Center(child: Text("No team members found"))
                : ListView.builder(
              itemCount: searchMember.length,
              itemBuilder: (context, index) {
                final member = searchMember[index];
                final attendance = memberAttendance[member['id']];
                final userStatus = attendance?['check_in_time'];
                final userCheckout=attendance?['check_out_time'];
                final bool status = userStatus != null && userStatus.toString().isNotEmpty && (userCheckout==null || userCheckout.toString().isEmpty);

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: (member['avatar_url'] == null || member['avatar_url'].isEmpty)
                            ? const AssetImage("assets/images/avatar.png") as ImageProvider
                            : NetworkImage(member['avatar_url']),
                      ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color:status? Colors.green:Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark?Colors.white54:Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(member['full_name'] ?? 'Unknown'),
                  subtitle: Text(member['designation']?.toString().trim() ?? 'Customer Support Executive'),
                  trailing: PopupMenuButton<String>(
                    color: Colors.grey[900],
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {},
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        child: TextButton(
                          onPressed: () {
                            final String? userPhoneNo = member['phone']?.toString();
                            if (kDebugMode) {
                              print("User phone no is $userPhoneNo");
                            }
                            if (userPhoneNo != null && userPhoneNo.trim().isNotEmpty) {
                              _makePhoneCall(userPhoneNo);
                            } else {
                              CustomSnackbar.show(
                                context: context,
                                label: "Looks like this user hasn't added a phone number yet!",
                              );
                            }
                          },
                          child: const Text(
                            "Call Now",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
