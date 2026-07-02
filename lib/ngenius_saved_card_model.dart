class NGeniusSavedCardModel {
  final String maskedPan;
  final String expiry;
  final String cardholderName;
  final String scheme;
  final String cardToken;
  final bool? recaptureCsc;

  NGeniusSavedCardModel({
    required this.maskedPan,
    required this.expiry,
    required this.cardholderName,
    required this.scheme,
    required this.cardToken,
    this.recaptureCsc,
  });

  factory NGeniusSavedCardModel.fromJson(Map<String, dynamic> json) {
    return NGeniusSavedCardModel(
      maskedPan: json['maskedPan'] as String,
      expiry: json['expiry'] as String,
      cardholderName: json['cardholderName'] as String,
      scheme: json['scheme'] as String,
      cardToken: json['cardToken'] as String,
      recaptureCsc: json['recaptureCsc'] != null ? json['recaptureCsc'] as bool : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maskedPan': maskedPan,
      'expiry': expiry,
      'cardholderName': cardholderName,
      'scheme': scheme,
      'cardToken': cardToken,
      'recaptureCsc': recaptureCsc,
    };
  }
}