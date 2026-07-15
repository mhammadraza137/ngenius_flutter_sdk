import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:ngenius_flutter_sdk/ngenius_flutter_sdk.dart';
import 'package:ngenius_flutter_sdk/ngenius_response_model.dart';
import 'package:ngenius_flutter_sdk/ngenius_saved_card_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'N-Genius Payment Integration',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Deep Blue theme
          brightness: Brightness.light,
        ),
      ),
      home: const NgeniusPaymentDashboard(),
    );
  }
}

/// A dashboard containing both Standard Card Payment and Saved Card Payment flows.
class NgeniusPaymentDashboard extends StatefulWidget {
  const NgeniusPaymentDashboard({super.key});

  @override
  State<NgeniusPaymentDashboard> createState() => _NgeniusPaymentDashboardState();
}

class _NgeniusPaymentDashboardState extends State<NgeniusPaymentDashboard> {
  final _ngeniusFlutterSdk = NgeniusFlutterSdk();

  // Saved Card Text Controllers
  final _maskedPanController = TextEditingController(text: '400555******0001');
  final _expiryController = TextEditingController(text: '2028-12');
  final _cardholderNameController = TextEditingController(text: 'John Doe');
  final _schemeController = TextEditingController(text: 'VISA');
  final _cardTokenController = TextEditingController(text: 'dG9rZW5pemVkUGFuLyy8wMDAwMDAwNDI');
  final _cvvController = TextEditingController(text: '123');

  bool _recaptureCsc = true; // By default, user will be prompted for CVV if not provided
  bool _isLoading = false;

  @override
  void dispose() {
    _maskedPanController.dispose();
    _expiryController.dispose();
    _cardholderNameController.dispose();
    _schemeController.dispose();
    _cardTokenController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  /// Simulates a server-side API call to create an order.
  /// In a production environment, order creation must always be done on your secure backend.
  /// Refer to N-Genius docs: https://docs.ngenius-payments.com/reference/two-stage-payments-orders
  Future<Map<String, dynamic>> _simulateBackendCreateOrder({
    required double amount,
    required String currency,
    NGeniusSavedCardModel? savedCard,
  }) async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 800));

    // Base mock order JSON structure as expected by Ngenius SDK
    final Map<String, dynamic> mockOrder = {};

    // If implementing saved card payment, N-Genius requires the saved card metadata
    // inside the order object (or specifically set in the API request body when creating).
    if (savedCard != null) {
      final savedCardMap = savedCard.toJson();
      
      // 1. Root level
      mockOrder["savedCard"] = savedCardMap;
      
      // 2. Under paymentMethods
      if (mockOrder["paymentMethods"] is Map) {
        mockOrder["paymentMethods"]["savedCard"] = savedCardMap;
      }
      
      // 3. Under _embedded.payment[0]
      final paymentsList = mockOrder["_embedded"]["payment"] as List;
      if (paymentsList.isNotEmpty) {
        paymentsList[0]["savedCard"] = savedCardMap;
      }
    }

    setState(() {
      _isLoading = false;
    });

    return mockOrder;
  }

  /// Launches the standard Card Payment flow.
  Future<void> _handleStandardPayment() async {
    try {
      // 1. Create order by simulating server call
      final orderJsonObject = await _simulateBackendCreateOrder(
        amount: 10.00,
        currency: "AED",
      );

      log("Initiating standard payment with order: $orderJsonObject");

      // 2. Launch Card Payment sheet using SDK
      final ngeniusResponse = await _ngeniusFlutterSdk.launchCardPayment(
        orderJsonObject: orderJsonObject,
      );

      _showResponseSnackBar(ngeniusResponse);
    } catch (e, stackTrace) {
      log("Error launching standard payment: $e", error: e, stackTrace: stackTrace);
      _showErrorSnackBar(e.toString());
    }
  }

  /// Launches the Saved Card Payment flow.
  Future<void> _handleSavedCardPayment() async {
    try {
      // 1. Instantiate the Saved Card model using user input values
      final savedCard = NGeniusSavedCardModel(
        maskedPan: _maskedPanController.text.trim(),
        expiry: _expiryController.text.trim(),
        cardholderName: _cardholderNameController.text.trim(),
        scheme: _schemeController.text.trim(),
        cardToken: _cardTokenController.text.trim(),
        recaptureCsc: _recaptureCsc,
      );

      // 2. Simulate server-side API call containing the savedCard object in request body
      final orderJsonObject = await _simulateBackendCreateOrder(
        amount: 15.50,
        currency: "AED",
        savedCard: savedCard,
      );

      log("Initiating saved card payment with order: $orderJsonObject");

      final inputCvv = _cvvController.text.trim();
      final String? cvv = inputCvv.isNotEmpty ? inputCvv : null;

      // 3. Launch Saved Card Payment sheet using SDK
      // Pass the CVV if you want to skip CVV collection by the SDK.
      // Omit/pass null for CVV if user needs to enter it on the payment page.
      final ngeniusResponse = await _ngeniusFlutterSdk.launchSavedCardPayment(
        orderJsonObject: orderJsonObject,
        cvv: cvv,
      );

      _showResponseSnackBar(ngeniusResponse);
    } catch (e, stackTrace) {
      log("Error launching saved card payment: $e", error: e, stackTrace: stackTrace);
      _showErrorSnackBar(e.toString());
    }
  }

  void _showResponseSnackBar(NGeniusResponseModel response) {
    if (!mounted) return;

    final isSuccess = response.message == "PAYMENT_SUCCESSFUL";
    print("response :: ${response.message}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSuccess
              ? "Transaction Successful! Code: ${response.code}"
              : "Transaction Failed! Code: ${response.code} | Message: ${response.message}",
        ),
        backgroundColor: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String errorMsg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $errorMsg"),
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('N-Genius Payment SDK Demo'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.credit_card), text: 'Standard Card'),
              Tab(icon: Icon(Icons.bookmark), text: 'Saved Card'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildStandardTab(),
                  _buildSavedCardTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildStandardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Standard Card Payment Flow',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'This flow simulates creating a standard card payment order on the backend '
                    'and launching the SDK\'s payment sheet where the customer inputs card details.',
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Amount to Pay:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('10.00 AED', style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: _handleStandardPayment,
            icon: const Icon(Icons.payment),
            label: const Text('Launch Card Payment', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                    'Use a tokenized card stored securely to initiate payments directly. '
                    'The order creation backend call includes the saved card details.',
                  ),
                  const Divider(height: 24),
                  _buildTextField(_maskedPanController, 'Masked PAN', hint: '400555******0001'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_expiryController, 'Expiry Date (YYYY-MM)', hint: '2028-12'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(_schemeController, 'Scheme (VISA/MASTERCARD)', hint: 'VISA'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(_cardholderNameController, 'Cardholder Name', hint: 'John Doe'),
                  const SizedBox(height: 12),
                  _buildTextField(_cardTokenController, 'Saved Card Token'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _cvvController,
                    'CVV (Optional)',
                    hint: 'Leave empty to prompt user in SDK sheet',
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Recapture CSC/CVV'),
                    subtitle: const Text('Prompt user in SDK page if CVV is not supplied'),
                    value: _recaptureCsc,
                    onChanged: (val) {
                      setState(() {
                        _recaptureCsc = val;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Amount to Pay:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('15.50 AED', style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: _handleSavedCardPayment,
            icon: const Icon(Icons.bookmark_added),
            label: const Text('Launch Saved Card Payment', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {String? hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
