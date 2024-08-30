import 'dart:ffi';

import 'package:dio/dio.dart';
import 'package:gagyebbyu_fe/models/account/account_recommendation.dart';
import 'package:gagyebbyu_fe/models/couple/couple_response.dart';
import 'package:gagyebbyu_fe/storage/TokenStorage.dart';
import 'package:flutter/material.dart';
import '../views/login/login_view.dart';
import '../services/navigation_service.dart';
import '../models/asset/asset_loan.dart';
import '../models/loan/loan.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  final NavigationService _navigationService;

  late Dio _dio;
  final TokenStorage _tokenStorage = TokenStorage();

  ApiService._internal() : _navigationService = NavigationService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://3.39.19.140:8080',
      connectTimeout: Duration(seconds: 15),
      receiveTimeout: Duration(seconds: 15),
    ));
    _dio.interceptors.add(TokenInterceptor(_tokenStorage, _dio, _navigationService));
  }

  Future<Response> get(String path) async {
    return await _dio.get(path);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

// 다른 HTTP 메서드들도 필요에 따라 추가...

// Loan API 메서드 추가
  Future<List<AssetLoan>> fetchAssetLoans() async {
    try {
      final response = await _dio.get('/api/asset-loans');
      if (response.statusCode == 200) {
        // 응답이 List<dynamic>임을 확인
        if (response.data is List) {
          return (response.data as List)
              .map((item) => AssetLoan.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Expected a list of loans but got ${response.data.runtimeType}');
        }
      } else {
        throw Exception('Failed to load asset loans');
      }
    } catch (e) {
      print('Error fetching asset loans: $e');
      rethrow;
    }
  }

  //커플의 대출 정보
  Future<List<AssetLoan>> fetchCoupleAssetLoans() async {
    try {
      final response = await _dio.get('/api/asset-loans/couple');
      if (response.statusCode == 200) {
        // 응답이 List<dynamic>임을 확인
        if (response.data is List) {
          return (response.data as List)
              .map((item) => AssetLoan.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Expected a list of loans but got ${response.data.runtimeType}');
        }
      } else {
        throw Exception('Failed to load asset loans');
      }
    } catch (e) {
      print('Error fetching asset loans: $e');
      rethrow;
    }
  }

  // couple 정보 가져오기
  Future<CoupleResponse> findCouple() async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      _dio.options.headers['Authorization'] = 'Bearer $accessToken';

      final response = await _dio.get('/api/couple');

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return CoupleResponse.fromJson(response.data);
        } else {
          throw Exception('Unexpected data format: ${response.data.runtimeType}');
        }
      } else {
        throw Exception('Failed to load couple data: ${response.statusCode}');
      }
    } on DioError catch (e) {
      print('Dio error: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Error fetching couple data: $e');
      throw Exception('Failed to fetch couple data: $e');
    }
  }

  //assetId를 가지고 asset-loans 검색
  Future<AssetLoan> fetchLoanDetail(int assetId) async {
    try {
      final response = await _dio.get('/api/asset-loans/$assetId');
      if (response.statusCode == 200) {
        return AssetLoan.fromJson(response.data);
      } else {
        throw Exception('Failed to load loan detail');
      }
    } catch (e) {
      print('Error fetching loan detail: $e');
      rethrow;
    }
  }

  //대출 총 남은 잔액 가져오는 api
  Future<int> fetchSumRemainAmount() async {
    try {
      final response = await _dio.get('/api/asset-loans/sum-user');
      if (response.statusCode == 200) {
        // API가 단일 Long 값을 반환하므로, 직접 정수로 변환
        return response.data as int;
      } else {
        throw Exception('Failed to load total remained amount');
      }
    } catch (e) {
      print('Error fetching total remained amount: $e');
      rethrow;
    }
  }

  //loan_info_page에서 사용하는 커플 정보
  Future<CoupleResponse> fetchCoupleInfo() async {
    try {
      final response = await _dio.get('/api/couple/loan');
      if (response.statusCode == 200) {
        return CoupleResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to load total remained amount');
      }
    } catch (e) {
      print('Error fetching total remained amount: $e');
      rethrow;
    }
  }


  // 커플 대출 정보 출력
  Future<List<AssetLoan>> fetchgetCoupleLoan() async {
    try {
      final response = await _dio.get('/api/asset-loans/couple');
      if (response.statusCode == 200) {
        List<dynamic> loansJson = response.data;
        print("-----loansJson loading is done!----");
        return loansJson.map((json) => AssetLoan.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recommended loans');
      }
    } catch (e) {
      print('Error fetching recommended loans: $e');
      rethrow;
    }
  }

  // 커플 적금 추천을 위한 api
  Future<AccountRecommendation> fetchAccountRecommendations() async {
    try {
      final depositResponse = await _dio.post('/api/recommend/deposit', data: {});
      final savingsResponse = await _dio.post('/api/recommend/savings', data: {});

      if (depositResponse.statusCode == 200 && savingsResponse.statusCode == 200) {
        return AccountRecommendation(
          depositAccounts: (depositResponse.data as List)
              .map((item) => RecommendedAccount.fromJson(item as Map<String, dynamic>))
              .toList(),
          savingsAccounts: (savingsResponse.data as List)
              .map((item) => RecommendedAccount.fromJson(item as Map<String, dynamic>))
              .toList(),
        );
      } else {
        throw Exception('Failed to load account recommendations');
      }
    } catch (e) {
      print('Error fetching account recommendations: $e');
      rethrow;
    }
  }
  //recommand 하려고 만든건데 일단 전체 보여줌
  Future<List<Loan>> fetchRecommendedLoans() async {
    try {
      final response = await _dio.post('/api/recommend/loan',data: {});
      if (response.statusCode == 200) {
        List<dynamic> loansJson = response.data;
        return loansJson.map((json) => Loan.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recommended loans');
      }
    } catch (e) {
      print('Error fetching recommended loans: $e');
      rethrow;
    }
  }
}


class TokenInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio;
  final NavigationService _navigationService;

  TokenInterceptor(this._tokenStorage, this._dio, this._navigationService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    String? accessToken = await _tokenStorage.getAccessToken();
    options.headers['Authorization'] = 'Bearer $accessToken';
    return handler.next(options);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // AccessToken이 만료된 경우
      if (await _refreshToken()) {
        // 토큰 갱신 성공, 원래 요청 재시도
        return handler.resolve(await _retry(err.requestOptions));
      } else {
        // 토큰 갱신 실패, 로그인 화면으로 이동
        _navigateToLogin();
      }
    }
    return handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      String? refreshToken = await _tokenStorage.getRefreshToken();
      final response = await _dio.post(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );
      if (response.statusCode == 200) {
        String newAccessToken = response.data['accessToken'];
        await _tokenStorage.saveTokens(newAccessToken, refreshToken!);
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
    return false;
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request<dynamic>(requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: options);
  }

  void _navigateToLogin() {
    _navigationService.navigateToReplacement(LoginView());
  }
}
