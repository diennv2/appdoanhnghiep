import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../model/user_location_model.dart';
import '../widgets/custom_info.dart';

class ProfessionalDetails extends StatefulWidget {
  const ProfessionalDetails({super.key});

  @override
  State<ProfessionalDetails> createState() => _ProfessionalDetailsState();
}

class _ProfessionalDetailsState extends State<ProfessionalDetails> {
  String? _activeField;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DatabaseHelperProvider>();
      provider.fetchUserProfile();
    });
  }

  Future<void> _updateField(String key, dynamic value) async {
    await Provider.of<DatabaseHelperProvider>(context, listen: false)
        .updateUserField(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final dbProvider = Provider.of<DatabaseHelperProvider>(context);
    final profile = dbProvider.profile;

    return SafeArea(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() => _activeField = null);
        },
        child: dbProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : profile == null
            ? const Center(child: Text('No profile data available.'))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(5),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoTile(
                    title: "Employee ID",
                    value: profile["employee_id"].toString() ?? "",
                    fieldKey: "employee_id",
                    activeField: _activeField,
                    onChanged: (newValue) {
                      _updateField("employee_id", newValue);
                    },
                    onFocusChange: (isFocused) {
                      setState(() => _activeField =
                      isFocused ? "employee_id" : null);
                    },
                  ),
                  InfoTile(
                    title: "Designation",
                    value: profile["designation"] ?? "",
                    fieldKey: "designation",
                    activeField: _activeField,
                    onChanged: (newValue) {
                      _updateField("designation", newValue);
                    },
                    onFocusChange: (isFocused) {
                      setState(() => _activeField =
                      isFocused ? "designation" : null);
                    },
                  ),
                  InfoTile(
                    title: "Employee Type",
                    isDropdown: true,
                    isEmployeeType: true,
                    value: profile["employee_type"] ?? "",
                    fieldKey: "employee_type",
                    activeField: _activeField,
                    onItemChanged: (newValue) {
                      _updateField("employee_type", newValue!);
                    },
                    onFocusChange: (isFocused) {
                      setState(() => _activeField =
                      isFocused ? "employee_type" : null);
                    },
                  ),
                  InfoTile(
                    readOnly: true,
                    isExperience:true,
                    title: "Company Experience",
                    value: profile["company_experience"] ?? "",
                    fieldKey: "company_experience",
                    activeField: _activeField,
                    onChanged: (newValue) {
                      _updateField("company_experience", newValue);
                    },
                    onFocusChange: (isFocused) {
                      setState(() => _activeField =
                      isFocused ? "company_experience" : null);
                    },
                  ),
                  InfoTile(
                    title: "Office Time",
                    isOfficeTime:true,
                    readOnly: true,
                    value: profile["office_time"] ?? "",
                    fieldKey: "office_time",
                    activeField: _activeField,
                    onChanged: (newValue) {
                      _updateField("office_time", newValue);
                    },
                  ),
                  InfoTile(
                    isDropdown: true,
                    isLocation: true,
                    value: profile["work _location"] ?? "",
                    title: "Work Location",
                    fieldKey: "work_location",
                    activeField: _activeField,
                    onItemChanged: (newValue) async {
                      final selectedLocation = UserLocationModel.locationList.firstWhere(
                            (loc) => loc.address == newValue,
                        orElse: () => UserLocationModel(address: '', latitude: 0, longitude: 0),
                      );

                      await _updateField("work _location", newValue!);
                      await _updateField("latitude", selectedLocation.latitude);
                      await _updateField("longitude", selectedLocation.longitude);
                    },
                    onFocusChange: (isFocused) {
                      setState(() => _activeField = isFocused ? "work_location" : null);
                    },
                  ),
                  InfoTile(
                    title: "Joining Date",
                    value: profile["joining_date"] ?? "",
                    fieldKey: "joining_date",
                    isDate: true,
                    onChanged: (newValue) {
                      _updateField("joining_date", newValue);
                    },

                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
