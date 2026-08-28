// Custom Attendance Card
import 'package:flutter/material.dart';

Widget customAdminCard(
    String title,
    IconData iconData,
    bool isDark,
  { String? status,
    bool isSmallScreen=false}) {
  return Container(
    decoration: BoxDecoration(
      color: isDark ? Color(0xff101317) : Color(0xfff8f8f8),
      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
    ),
    padding: EdgeInsets.all(isSmallScreen ? 10 : 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isSmallScreen ? 32 : 39,
          height: isSmallScreen ? 32 : 39,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSmallScreen ? 4 : 5),
            color:isDark? Color(0x57194BAF): Color(0x47ffffff),
          ),
          child:  Center(child: Icon(iconData, color: Colors.blueAccent, size: isSmallScreen ? 20 : 26)),
        ),
        SizedBox(height: isSmallScreen ? 8 : 10),
        Flexible(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: isSmallScreen ? 12 : 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: isSmallScreen ? 3 : 4),
        Text(
          status ?? "",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: isSmallScreen ? 16 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),

      ],
    ),
  );
}