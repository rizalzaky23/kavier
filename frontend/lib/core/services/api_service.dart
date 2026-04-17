import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://localhost:8000/api';
  }

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );

    // Auto-inject token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: false,
      requestBody: true,
      responseBody: true,
      compact: true,
    ));
  }

  Dio get dio => _dio;

  // ── Auth ──────────────────────────────────────────────────────────────

  Future<Response> login(String email, String password) {
    return _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> logout() => _dio.post('/auth/logout');

  // ── Categories ────────────────────────────────────────────────────────

  Future<Response> getCategories() => _dio.get('/categories');

  Future<Response> createCategory(Map<String, dynamic> data) =>
      _dio.post('/categories', data: data);

  Future<Response> updateCategory(int id, Map<String, dynamic> data) =>
      _dio.put('/categories/$id', data: data);

  Future<Response> deleteCategory(int id) => _dio.delete('/categories/$id');

  // ── Products ──────────────────────────────────────────────────────────

  Future<Response> getProducts({
    String? search,
    int? categoryId,
    int? perPage,
  }) {
    return _dio.get('/products', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': categoryId,
      if (perPage != null) 'per_page': perPage,
    });
  }

  Future<Response> getProduct(int id) => _dio.get('/products/$id');

  Future<Response> createProduct(FormData data) =>
      _dio.post('/products', data: data);

  Future<Response> updateProduct(int id, FormData data) =>
      _dio.post('/products/$id', data: data..fields.add(const MapEntry('_method', 'PUT')));

  Future<Response> deleteProduct(int id) => _dio.delete('/products/$id');

  Future<Response> getLowStock() => _dio.get('/products/low-stock');

  // ── Transactions ──────────────────────────────────────────────────────

  Future<Response> getTransactions({
    String? dateFrom,
    String? dateTo,
    int? perPage,
  }) {
    return _dio.get('/transactions', queryParameters: {
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null)   'date_to': dateTo,
      if (perPage != null)  'per_page': perPage,
    });
  }

  Future<Response> createTransaction(Map<String, dynamic> data) =>
      _dio.post('/transactions', data: data);

  Future<Response> cancelTransaction(int id) =>
      _dio.patch('/transactions/$id/cancel');

  // ── Reports ───────────────────────────────────────────────────────────

  Future<Response> getReportSummary({
    String period = 'daily',
    String? dateFrom,
    String? dateTo,
  }) {
    return _dio.get('/reports/summary', queryParameters: {
      'period': period,
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null)   'date_to': dateTo,
    });
  }

  Future<Response> getTopProducts({String period = 'monthly'}) =>
      _dio.get('/reports/top-products', queryParameters: {'period': period});

  Future<Response> getDailyChart() => _dio.get('/reports/daily-chart');
}
