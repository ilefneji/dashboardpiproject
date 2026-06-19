
class Config {
  final int? id;
  final double priceSubscription;
  final String? createdAt;

  Config({
    this.id,
    required this.priceSubscription,
    this.createdAt,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      id: json['id'],
      priceSubscription: json['priceSubscription'] != null
          ? double.parse(json['priceSubscription'].toString())
          : 0.0,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'priceSubscription': priceSubscription,
    };
  }
}
