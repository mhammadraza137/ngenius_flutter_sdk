# N-Genius Flutter SDK

N-Genius Flutter SDK provides an easy-to-use integration for handling payments using N-Genius APIs in Flutter applications.

## 📱 Platform Compatibility
- **Android** ✅


 <img src="https://github.com/user-attachments/assets/32896dc7-8056-4665-bd67-f992cad888f3" width="360" height="720" alt="android_ngenius_gif"/>


- **iOS** ✅ (Minimum deployment target: iOS 12.0)


<img src="https://github.com/user-attachments/assets/235cfc4f-05ef-4497-8e99-5aa66b8e9876" width="360" height="720" alt="ios_ngenius_gif"/>



## ⚙️ Android Configuration
### **Tested Environment**
This plugin has been tested with:
- **Android Gradle Plugin (AGP):** `8.1.0` [See here](https://github.com/mhammadraza137/ngenius_flutter_sdk/blob/d61f58d72b17127b11308ed4e3c29563b5184fd7/example/android/settings.gradle#L21)
- **Kotlin Version:** `1.8.22` [See here](https://github.com/mhammadraza137/ngenius_flutter_sdk/blob/d61f58d72b17127b11308ed4e3c29563b5184fd7/example/android/settings.gradle#L22)
- **Gradle Distribution:** `8.3` [See here](https://github.com/mhammadraza137/ngenius_flutter_sdk/blob/d61f58d72b17127b11308ed4e3c29563b5184fd7/example/android/gradle/wrapper/gradle-wrapper.properties#L5)

### **Project-Level `build.gradle` Changes**
Since N-Genius SDK is a **JitPack dependency**, add the following line inside the `allprojects` repositories block in your **project-level** `android/build.gradle` file:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' } // Add this line
    }
}
```

## 🍏 iOS Configuration
No additional configuration is required for iOS.

## 🔄 N-Genius Response Model
The plugin returns a response object containing a **message** and a **code**. Below are the possible response scenarios:

### **🛑 Transaction Cancellation & Errors**
| Condition | Message | Code |
|-----------|------------|------|
| User cancels the transaction | `CANCELLED_BY_USER` | `401` |
| Order expired or generic error | `STATUS_GENERIC_ERROR` | `-1` |
| Payment failed | `STATUS_PAYMENT_FAILED` | `0` |

### **✅ Successful Payment Responses**
#### **🟢 Android**
| Payment Status | Message | Code |
|---------------|----------------------|------|
| Payment authorized | `PAYMENT_SUCCESSFUL` | `1` |
| Payment captured | `PAYMENT_SUCCESSFUL` | `2` |
| Payment purchased | `PAYMENT_SUCCESSFUL` | `3` |
| Post authorization review | `PAYMENT_SUCCESSFUL` | `4` |

#### **🍏 iOS**
The native **iOS N-Genius SDK** does not provide specific statuses like **authorized, captured, or purchased**. Instead, it returns a **generic success response**:

| Condition | Message | Code |
|-----------|----------------------|------|
| Transaction successful | `PAYMENT_SUCCESSFUL` | `200` |

---

### 🚀 **Get Started with N-Genius Flutter SDK**
1. Install the plugin in your Flutter project.
2. Configure **Android settings** as mentioned above.
3. Call the **N-Genius SDK** to launch the payment flow.

---

#### **Example Implementation (Normal Payment)**
```dart
class NgeniusExample extends StatelessWidget {
  const NgeniusExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('N-Genius Example'),
      ),
      body: Center(
        child: ElevatedButton(
            onPressed: () async {
              final ngeniusFlutterSdk = NgeniusFlutterSdk();
              NGeniusResponseModel ngeniusResponse = await ngeniusFlutterSdk.launchCardPayment(orderJsonObject: {});
              if (context.mounted) {
                if (ngeniusResponse.message == "PAYMENT_SUCCESSFUL") {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Transaction Successful")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Transaction Failed :: code :: ${ngeniusResponse.code} :: message :: ${ngeniusResponse.message}")));
                }
              }
            },
            child: Text("Launch Card Payment")),
      ),
    );
  }
}
```
---

#### **Example Implementation (for using Saved Cards)**

> **Note:** The key difference when using a saved card is in the **order creation step**. You must pass a `savedCard` object (`NGeniusSavedCardModel`) in your `createOrder` request body. If `recaptureCsc` is set to `true`, the user will be prompted to enter their CVV — you can skip this by passing the `cvv` directly to `launchSavedCardPayment`.

```dart
class NgeniusSavedCardExample extends StatelessWidget {
  const NgeniusSavedCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('N-Genius Saved Card Example'),
      ),
      body: Center(
        child: ElevatedButton(
            onPressed: () async {
              // 1. Build your saved card model from your stored card data
              final savedCard = NGeniusSavedCardModel(
                maskedPan: "400555******0001",
                expiry: "2025-12",
                cardholderName: "John Doe",
                scheme: "VISA",
                cardToken: "your-card-token",
                recaptureCsc: true, // true = user will be prompted for CVV
              );

              // 2. Call YOUR backend/API to create the order.
              // This is not part of the plugin — you are responsible for
              // implementing this API call following the N-Genius documentation:
              // https://docs.ngenius-payments.com/reference/two-stage-payments-orders
              // The savedCard object must be included in the request body.
              final Map<String, dynamic> orderJsonObject = await yourApiService.createOrder(
                amountValue: 10.50,
                currency: "AED",
                savedCard: savedCard,
              );

              // 3. Launch saved card payment
              // Pass cvv to skip the CVV page, or omit it to let the user enter it
              final ngeniusFlutterSdk = NgeniusFlutterSdk();
              NGeniusResponseModel ngeniusResponse = await ngeniusFlutterSdk.launchSavedCardPayment(
                orderJsonObject: orderJsonObject, 
                //cvv: "123" //If you want your UI to handle CVV
              );

              if (context.mounted) {
                if (ngeniusResponse.message == "PAYMENT_SUCCESSFUL") {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Transaction Successful")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Transaction Failed :: code :: ${ngeniusResponse.code} :: message :: ${ngeniusResponse.message}")));
                }
              }
            },
            child: Text("Launch Saved Card Payment")),
      ),
    );
  }
}
```

---

## 🔄 N-Genius SavedCard Model

| Parameter      | Example                                | DataType   |
|----------------|----------------------------------------|------------|
| maskedPan      | `400555******0001`                     | `String`   |
| expiry         | `"2025-12"`                            | `String`   |
| cardholderName | `"John Doe"`                           | `String`   |
| scheme         | `"VISA"`                               | `String`   |
| cardToken      | `"your-card-token"`                    | `String`   |
| recaptureCsc   | `true` = user will be prompted for CVV | `boolean`  |

---

### **Passing the Order JSON Object to `launchCardPayment` Method**

To pass the `orderJsonObject` to the `launchCardPayment` method, you need to provide it against the `orderJsonObject` key. To get the `orderJsonObject`, you must first call two APIs. It is recommended to call these APIs on the server-side, not on the mobile side, for security and performance reasons.

#### **Steps to Get the Order JSON Object**

1- **Get the Access Token**  
   First, you need to obtain the access token by following the official N-Genius documentation:  
   [Request an Access Token](https://docs.ngenius-payments.com/reference/request-an-access-token-direct)

2- **Get the Order Object**  
   Once you have the access token, use it to call the API to get the order object. For more information, refer to the N-Genius documentation:  
   [Two-Stage Payments Orders](https://docs.ngenius-payments.com/reference/two-stage-payments-orders)

#### **Sample Order JSON Object**

After calling the APIs, you will receive the N-Genius order object. You can check the structure of the order object by referring to the official sample here:  
[Order Object in Full](https://docs.ngenius-payments.com/reference/the-order-object-in-full)

---

### **Getting the Saved-Card Token**

1- Ensure that Tokenization is enabled for your merchant account.

2- After a successful payment, retrieve the order details using the following endpoint:
`GET /transactions/outlets/{{outletId}}/orders/{{orderId}}`

3- The saved card token is returned in the response at:
`_embedded.payment.savedCard.cardToken`

You can use this token to perform future saved card payments without requiring the customer to re-enter their card details.

---

### **Test Payment Using N-Genius Test Cards**

You can test payment using test cards for N-Genius from the following link:  
[Sandbox Test Environment](https://docs.ngenius-payments.com/reference/sandbox-test-environment)



For detailed documentation, refer to the official N-Genius API documentation.


## License

This project is licensed under the [MIT License](https://github.com/mhammadraza137/ngenius_flutter_sdk/blob/main/LICENSE).

---
📌 **Note:** If you encounter any issues, ensure all dependencies and configurations match the tested environment.

Happy coding! 🎉


