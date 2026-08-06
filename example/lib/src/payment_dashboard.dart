import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ngenius_flutter_sdk/ngenius_flutter_sdk.dart';
import 'package:ngenius_flutter_sdk/ngenius_response_model.dart';
import 'package:ngenius_flutter_sdk/ngenius_saved_card_model.dart';

import 'ngenius_checkout_config.dart';
import 'ngenius_order_service.dart';

class NgeniusPaymentDashboard extends StatefulWidget {
  const NgeniusPaymentDashboard({super.key});

  @override
  State<NgeniusPaymentDashboard> createState() =>
      _NgeniusPaymentDashboardState();
}

class _NgeniusPaymentDashboardState extends State<NgeniusPaymentDashboard>
    with SingleTickerProviderStateMixin {
  static const _standardAmountMinorUnits = 1000;
  static const _savedCardAmountMinorUnits = 1550;
  static const _currencyCode = 'AED';

  final _ngeniusFlutterSdk = NgeniusFlutterSdk();
  final _orderService = const NgeniusOrderService();

  late final TabController _tabController;

  final _apiKeyController = TextEditingController(
    text: const String.fromEnvironment('NGENIUS_API_KEY'),
  );
  final _outletReferenceController = TextEditingController(
    text: const String.fromEnvironment('NGENIUS_OUTLET_REF'),
  );
  final _baseUrlController = TextEditingController(
    text: const String.fromEnvironment(
      'NGENIUS_BASE_URL',
      defaultValue: NgeniusCheckoutConfig.sandboxBaseUrl,
    ),
  );

  final _maskedPanController = TextEditingController(text: '400555******0001');
  final _expiryController = TextEditingController(text: '2030-12');
  final _cardholderNameController = TextEditingController(text: 'John Doe');
  final _schemeController = TextEditingController(text: 'VISA');
  final _cardTokenController =
      TextEditingController(text: 'dG9rZW5pemVkUGFuLy92MS8vU0hPV19OT05FLy8wMTAwMjEwNDIxMTE0MTcz');
  final _cvvController = TextEditingController(text: '123');

  bool _recaptureCsc = true;
  bool _isLoading = false;

  NgeniusCheckoutConfig get _config => NgeniusCheckoutConfig(
        apiKey: _apiKeyController.text,
        outletReference: _outletReferenceController.text,
        baseUrl: _baseUrlController.text.trim().isEmpty
            ? NgeniusCheckoutConfig.sandboxBaseUrl
            : _baseUrlController.text.trim(),
      );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiKeyController.dispose();
    _outletReferenceController.dispose();
    _baseUrlController.dispose();
    _maskedPanController.dispose();
    _expiryController.dispose();
    _cardholderNameController.dispose();
    _schemeController.dispose();
    _cardTokenController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _handleStandardPayment() async {
    await _runPaymentFlow(() async {
      final orderJsonObject = await _orderService.createPurchaseOrder(
        config: _config,
        amountMinorUnits: _standardAmountMinorUnits,
        currencyCode: _currencyCode,
      );

      log('Launching standard payment with order: $orderJsonObject');

      return _ngeniusFlutterSdk.launchCardPayment(
        orderJsonObject: orderJsonObject,
      );
    });
  }

  Future<void> _handleSavedCardPayment() async {
    await _runPaymentFlow(() async {
      final savedCard = NGeniusSavedCardModel(
        maskedPan: _maskedPanController.text.trim(),
        expiry: _expiryController.text.trim(),
        cardholderName: _cardholderNameController.text.trim(),
        scheme: _schemeController.text.trim(),
        cardToken: _cardTokenController.text.trim(),
        recaptureCsc: _recaptureCsc,
      );

      final orderJsonObject = await _orderService.createPurchaseOrder(
        config: _config,
        amountMinorUnits: _savedCardAmountMinorUnits,
        currencyCode: _currencyCode,
        savedCard: savedCard,
      );

      log('Launching saved card payment with order: $orderJsonObject');

      final inputCvv = _cvvController.text.trim();

      return _ngeniusFlutterSdk.launchSavedCardPayment(
        orderJsonObject: orderJsonObject,
        cvv: inputCvv.isEmpty ? null : inputCvv,
      );
    });
  }

  Future<void> _runPaymentFlow(
    Future<NGeniusResponseModel> Function() launchPayment,
  ) async {
    if (!_config.hasRequiredCredentials) {
      _showMissingCredentials();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await launchPayment();
      log('N-Genius payment response: ${response.code} :: ${response.message}');
      _showResponseSnackBar(response);
    } catch (error, stackTrace) {
      log('N-Genius payment flow failed', error: error, stackTrace: stackTrace);
      _showErrorSnackBar(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMissingCredentials() {
    _tabController.animateTo(0);
    _showErrorSnackBar('Add API Key and Outlet Reference first.');
  }

  void _showResponseSnackBar(NGeniusResponseModel response) {
    if (!mounted) return;

    final isSuccess = response.message == 'PAYMENT_SUCCESSFUL';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSuccess
              ? 'Transaction successful. Code: ${response.code}'
              : 'Transaction failed. Code: ${response.code} | Message: ${response.message}',
        ),
        backgroundColor:
            isSuccess ? Colors.green.shade700 : Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String errorMsg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMsg),
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('N-Genius Payment SDK Demo'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Config'),
            Tab(icon: Icon(Icons.credit_card), text: 'Card'),
            Tab(icon: Icon(Icons.bookmark), text: 'Saved Card'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildConfigTab(),
              _buildStandardTab(),
              _buildSavedCardTab(),
            ],
          ),
          if (_isLoading)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sandbox Credentials',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'For this example only. In production, create orders on your backend and never ship your API key in the app.',
                  ),
                  const Divider(height: 24),
                  _buildTextField(
                    _apiKeyController,
                    'API Key',
                    hint: 'Basic API key from N-Genius',
                    // obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _outletReferenceController,
                    'Outlet Reference',
                    hint: 'Your outlet reference',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _baseUrlController,
                    'Base URL',
                    hint: NgeniusCheckoutConfig.sandboxBaseUrl,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Use These Credentials'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'You can also launch with --dart-define=NGENIUS_API_KEY=... --dart-define=NGENIUS_OUTLET_REF=...',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardTab() {
    return _buildPaymentTab(
      title: 'Standard Card Payment Flow',
      description:
          'Creates an N-Genius sandbox PURCHASE order, then launches the SDK card payment screen.',
      amountLabel: '10.00 AED',
      buttonIcon: Icons.payment,
      buttonLabel: 'Launch Card Payment',
      onPressed: _handleStandardPayment,
    );
  }

  Widget _buildSavedCardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCredentialsWarning(),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved Card Payment Flow',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Creates an order with savedCard metadata, then launches the SDK saved-card payment flow.',
                  ),
                  const Divider(height: 24),
                  _buildTextField(
                    _maskedPanController,
                    'Masked PAN',
                    hint: '400555******0001',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _expiryController,
                          'Expiry Date',
                          hint: '2030-12',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _schemeController,
                          'Scheme',
                          hint: 'VISA',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _cardholderNameController,
                    'Cardholder Name',
                    hint: 'John Doe',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(_cardTokenController, 'Saved Card Token'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _cvvController,
                    'CVV',
                    hint: 'Leave empty to prompt user in SDK sheet',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Recapture CSC/CVV'),
                    subtitle: const Text('Prompt user if CVV is not supplied'),
                    value: _recaptureCsc,
                    onChanged: (value) => setState(() => _recaptureCsc = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 24),
                  _buildAmountRow('Amount to Pay:', '15.50 AED'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLaunchButton(
            icon: Icons.bookmark_added,
            label: 'Launch Saved Card Payment',
            onPressed: _handleSavedCardPayment,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTab({
    required String title,
    required String description,
    required String amountLabel,
    required IconData buttonIcon,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCredentialsWarning(),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(description),
                  const Divider(height: 24),
                  _buildAmountRow('Amount to Pay:', amountLabel),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLaunchButton(
            icon: buttonIcon,
            label: buttonLabel,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsWarning() {
    if (_config.hasRequiredCredentials) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Configure API Key and Outlet Reference first.'),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(0),
                child: const Text('Open'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLaunchButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildAmountRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
