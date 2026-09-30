import 'package:geocoding/geocoding.dart';

class LocationAddressService {
  LocationAddressService._();

  static Future<String?> getAddress({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final geocoding = Geocoding();

      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) return null;

      final p = placemarks.first;

      final parts =
          <String?>[
                p.name,
                p.street,
                p.subLocality,
                p.locality,
                p.subAdministrativeArea,
                p.administrativeArea,
                p.postalCode,
                p.country,
              ]
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList();

      return parts.isEmpty ? null : parts.join(', ');
    } catch (e) {
      return null;
    }
  }
}
