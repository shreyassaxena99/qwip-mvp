class Pod {
  final String id;
  final String name;
  final String address;
  final String description;
  final String openingTime;
  final String closingTime;
  final double latitude;
  final double longitude;
  final int price;

  Pod({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.openingTime,
    required this.closingTime,
    required this.latitude,
    required this.longitude,
    required this.price,
  });

  // Converts the Pod object into a map-like string
  @override
  String toString() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'description': description,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'latitude': latitude,
      'longitude': longitude,
      'price': price,
    }.toString();
  }

  factory Pod.fromFirestore(String id, Map<String, dynamic> data) {
    if (data['name'] is! String ||
        data['address'] is! String ||
        data['description'] is! String ||
        data['opening_time'] is! String ||
        data['closing_time'] is! String ||
        data['latitude'] is! double ||
        data['longitude'] is! double ||
        data['price'] is! int) {
      throw Exception('Invalid data format for pod: $id');
    }

    return Pod(
      id: id,
      name: data['name'],
      address: data['address'],
      description: data['description'],
      openingTime: data['opening_time'],
      closingTime: data['closing_time'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      price: data['price'],
    );
  }
}
