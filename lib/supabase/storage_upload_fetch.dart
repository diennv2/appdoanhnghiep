  import 'dart:io';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/foundation.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';

  class ImageUpload {
    final FirebaseAuth auth = FirebaseAuth.instance;

    /// Upload image only if the user is authenticated
    Future<void> uploadImage(File? image) async {
      final currUser = auth.currentUser;

      if (currUser == null) {
        if (kDebugMode) print('User is not authenticated');
        return;
      }

      if (image == null) {
        if (kDebugMode) print('No image selected');
        return;
      }

      final imageSize = await image.length();
      if (imageSize > 34 * 1024 * 1024) {
        if (kDebugMode) print('File is too large');
        return;
      }

      try {
        final fileName = currUser.uid;
        final filePath = 'avatars/${currUser.uid}/$fileName';

        final response = await Supabase.instance.client.storage
            .from('avatars')
            .upload(
          filePath,
          image,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/jpeg',

          ),
        );

        if (kDebugMode) print('Image uploaded to: $response');
      } catch (e) {
        if (kDebugMode) print("Error uploading image: $e");
      }
    }

    /// Fetch public image URL for viewing
    Future<String?> getImageUrl() async {
      final currUser = auth.currentUser;

      if (currUser == null) {
        if (kDebugMode) print('User is not authenticated');
        return null;
      }

      try {
        final fileName = currUser.uid;
        final filePath = 'avatars/${currUser.uid}/$fileName';

        final response = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(filePath);

        return response;
      } catch (e) {
        if (kDebugMode) print("Error fetching image URL: $e");
        return null;
      }
    }
  }
