import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final Position position;
  final String placeName;

  const LocationResult({required this.position, required this.placeName});
}

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it from Settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    final placeName = await _getPlaceName(
      position.latitude,
      position.longitude,
    );

    return LocationResult(position: position, placeName: placeName);
  }

  Future<String> _getPlaceName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return 'Current location';
      }

      final place = placemarks.first;
      final parts = <String>[];

      void add(String? value) {
        final text = value?.trim();
        if (text != null && text.isNotEmpty && !parts.contains(text)) {
          parts.add(text);
        }
      }

      add(place.street);
      add(place.subLocality);
      add(place.locality);
      add(place.administrativeArea);
      add(place.country);

      return parts.isEmpty ? 'Current location' : parts.join(', ');
    } catch (_) {
      return 'Current location';
    }
  }
}
