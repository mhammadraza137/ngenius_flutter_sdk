# N-Genius Flutter SDK Example

This app demonstrates standard card and saved-card payments with the
`ngenius_flutter_sdk` plugin.

## Run the example

Install dependencies and start the app:

```sh
flutter pub get
flutter run
```

Open the **Config** tab and enter:

- **API Key**: the sandbox API key value. Do not include the `Basic` prefix.
- **Outlet Reference**: the sandbox outlet reference.
- **Base URL**: defaults to the N-Genius sandbox API gateway.

The values can also be supplied at launch time:

```sh
flutter run \
  --dart-define=NGENIUS_API_KEY=your_api_key \
  --dart-define=NGENIUS_OUTLET_REF=your_outlet_reference
```

Use `NGENIUS_BASE_URL` only when you need to override the sandbox gateway.

## Payment flows

The **Card** tab requests an access token, creates a purchase order, and passes
the complete order response to `launchCardPayment`.

The **Saved Card** tab adds `NGeniusSavedCardModel` to the create-order request
and passes the returned order to `launchSavedCardPayment`. Tokenization must be
enabled for the outlet, and the card token must come from a previous tokenized
payment. When CVV is omitted and `recaptureCsc` is enabled, the native SDK asks
the customer to enter it.

## Security

This example calls N-Genius directly so plugin behavior can be tested easily.
Do not embed an N-Genius API key in a production mobile app. Create access
tokens and orders on a trusted backend, then send only the order response to
the app.

Android requires internet access; the example manifest already includes the
`android.permission.INTERNET` permission. No extra iOS configuration is needed.
