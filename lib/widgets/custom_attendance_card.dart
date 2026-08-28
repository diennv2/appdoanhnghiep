// Custom Attendance Card
import 'package:flutter/material.dart';

Widget attendanceCard(
    String title,
    String time,
    String status,
    IconData iconData,
    bool isDark,{bool isSmallScreen=false}) {
  return Container(
    decoration: BoxDecoration(
      color: isDark ? Color(0xff101317) : Color(0xfff8f8f8),
      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
    ),
    padding: EdgeInsets.all(isSmallScreen ? 10 : 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
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


             SizedBox(width: isSmallScreen ? 8 : 10),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

         SizedBox(height: isSmallScreen ? 4 : 6),
        Text(
          time,
          textAlign: TextAlign.left,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: isSmallScreen ? 16 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
         SizedBox(height: isSmallScreen ? 2 : 4),
        Text(
          status,
          textAlign: TextAlign.left,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: isSmallScreen ? 10 : 12,
          ),
        ),
      ],
    ),
  );
}