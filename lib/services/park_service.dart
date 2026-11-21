import 'dart:convert';
import 'package:http/http.dart' as http;

class ParkService {
  static Future<List<Map<String, dynamic>>> fetchNearbyParks(double lat, double lon) async {
    final query = '[out:json];node["leisure"="park"](around:3000,$lat,$lon);out 20;';
    final url = Uri.parse(
      'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List elements = data['elements'];
        return elements.map((e) {
          final tags = e['tags'] ?? {};
          return {
            'name': tags['name'] ?? 'Parque Público',
            'lat': e['lat'],
            'lon': e['lon'],
          };
        }).toList();
      }
    } catch (e) {
      print('Error al consultar API de parques: $e');
    }
    return [];
  }
}