import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomUpdateDialog extends StatelessWidget {
  final String title;
  final String message;
  final String newVersion;
  final String currentVersion;
  final String storeUrl;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  const CustomUpdateDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.newVersion,
    required this.currentVersion,
    required this.storeUrl,
    required this.onUpdate,
    this.onLater,
  }) : super(key: key);

  Future<void> _launchStore() async {
    try {
      if (await canLaunchUrl(Uri.parse(storeUrl))) {
        await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
      } else {
        throw 'Không thể mở $storeUrl';
      }
    } catch (e) {
      print('Error launching store: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phiên bản hiện tại: $currentVersion',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phiên bản mới: $newVersion',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (onLater != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onLater?.call();
            },
            child: const Text('Sau'),
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _launchStore();
            onUpdate.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cập nhật ngay'),
        ),
      ],
    );
  }
}
