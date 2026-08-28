import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class DioService {
  static final DioService _instance = DioService._internal();
  late final Dio _dio;

  factory DioService() {
    return _instance;
  }

  DioService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.BASE_URL,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // SSL bypass for debug only
    if (!kReleaseMode) {
      final adapter = _dio.httpClientAdapter;
      if (adapter is IOHttpClientAdapter) {
        adapter.createHttpClient = () {
          final client = HttpClient();

          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) {
            if (host == 'chamcongdoanhnghiep.techber.vn') {
              debugPrint(
                '⚠️ Accepting bad SSL certificate for $host:$port in debug mode only',
              );
              return true;
            }
            return false;
          };

          return client;
        };
      }
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();

          // ưu tiên key mới, fallback key cũ
          final token =
              prefs.getString('token') ??
                  prefs.getString('access_token');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            debugPrint('➡️ [${options.method}] ${options.baseUrl}${options.path}');
            debugPrint('Headers: ${options.headers}');
            debugPrint('Data: ${options.data}');
            debugPrint('Query: ${options.queryParameters}');
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '✅ [${response.statusCode}] ${response.requestOptions.method} ${response.requestOptions.baseUrl}${response.requestOptions.path}',
            );
            debugPrint('Response: ${response.data}');
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            debugPrint(
              '❌ [${error.response?.statusCode}] ${error.requestOptions.method} ${error.requestOptions.baseUrl}${error.requestOptions.path}',
            );
            debugPrint('Error: ${error.message}');
            debugPrint('Response: ${error.response?.data}');
          }

          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}