class NgeniusCheckoutConfig {
  const NgeniusCheckoutConfig({
    required this.apiKey,
    required this.outletReference,
    required this.baseUrl,
  });

  static const sandboxBaseUrl =
      'https://api-gateway.sandbox.ngenius-payments.com';

  final String apiKey;
  final String outletReference;
  final String baseUrl;

  bool get hasRequiredCredentials =>
      apiKey.trim().isNotEmpty && outletReference.trim().isNotEmpty;
}
