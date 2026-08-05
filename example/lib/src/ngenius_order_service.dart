import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ngenius_flutter_sdk/ngenius_saved_card_model.dart';

import 'ngenius_checkout_config.dart';

class NgeniusOrderService {
  const NgeniusOrderService({HttpClient? httpClient})
      : _httpClient = httpClient;

  final HttpClient? _httpClient;

  Future<Map<String, dynamic>> createPurchaseOrder({
    required NgeniusCheckoutConfig config,
    required int amountMinorUnits,
    required String currencyCode,
    NGeniusSavedCardModel? savedCard,
  }) async {
    final accessToken = await _requestAccessToken(config);

    return _createOrder(
      config: config,
      accessToken: accessToken,
      amountMinorUnits: amountMinorUnits,
      currencyCode: currencyCode,
      savedCard: savedCard,
    );
  }

  Future<String> _requestAccessToken(NgeniusCheckoutConfig config) async {
    final uri = Uri.parse(
      '${config.baseUrl}/identity/auth/access-token',
    );

    final response = await _postJson(
      uri: uri,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/vnd.ni-identity.v1+json',
        HttpHeaders.authorizationHeader: 'Basic ${config.apiKey.trim()}',
      },
    );

    final accessToken = response['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const NgeniusApiException('Access token was missing in response.');
    }

    return accessToken;
  }

  Future<Map<String, dynamic>> _createOrder({
    required NgeniusCheckoutConfig config,
    required String accessToken,
    required int amountMinorUnits,
    required String currencyCode,
    NGeniusSavedCardModel? savedCard,
  }) {
    final outletReference = Uri.encodeComponent(config.outletReference.trim());
    final uri = Uri.parse(
      '${config.baseUrl}/transactions/outlets/$outletReference/orders',
    );

    final body = <String, dynamic>{
      'action': 'PURCHASE',
      'amount': {
        'currencyCode': currencyCode,
        'value': amountMinorUnits,
      },
      if (savedCard != null) 'savedCard': savedCard.toJson(),
    };

    return _postJson(
      uri: uri,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        HttpHeaders.contentTypeHeader: 'application/vnd.ni-payment.v2+json',
        HttpHeaders.acceptHeader: 'application/vnd.ni-payment.v2+json',
      },
      body: body,
    );
  }

  Future<Map<String, dynamic>> _postJson({
    required Uri uri,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    final client = _httpClient ?? HttpClient();

    try {
      final request = await client.postUrl(uri).timeout(
            const Duration(seconds: 20),
          );

      headers.forEach(request.headers.set);

      if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(
            const Duration(seconds: 30),
          );
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NgeniusApiException(
          'N-Genius request failed (${response.statusCode}): $responseBody',
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const NgeniusApiException(
          'N-Genius response was not a JSON object.',
        );
      }

      return decoded;
    } on TimeoutException {
      throw const NgeniusApiException('N-Genius request timed out.');
    } on SocketException catch (error) {
      throw NgeniusApiException('Network error: ${error.message}');
    } on FormatException catch (error) {
      throw NgeniusApiException('Invalid JSON response: ${error.message}');
    } finally {
      if (_httpClient == null) {
        client.close();
      }
    }
  }
}

class NgeniusApiException implements Exception {
  const NgeniusApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
