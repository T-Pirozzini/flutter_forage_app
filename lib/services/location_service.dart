import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationService {
  var key = dotenv.env['PLACES_KEY'];

  Future<String> getPlaceId(String input) async {
    final String url =
        "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&key=$key";

    var response = await http.get(Uri.parse(url));

    var json = convert.jsonDecode(response.body);    

    if (json['candidates'] != null && json['candidates'].isNotEmpty) {
      var placeId = json['candidates'][0]['place_id'] as String;
      return placeId;
    } else {
      throw Exception('Place ID not found');
    }
  }

  Future<Map<String, dynamic>> getPlace(String input) async {
    final placeId = await getPlaceId(input);
    final String url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$key";

    var response = await http.get(Uri.parse(url));

    var json = convert.jsonDecode(response.body);

    var results = json['result'] as Map<String, dynamic>;

    return results;
  }

  Future<List<Map<String, dynamic>>> getPlaceSuggestions(String input) async {
    if (key == null) {
      throw Exception('Google Places API key is missing');
    }
    if (input.isEmpty) {
      return [];
    }
    final String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$key";

    try {
      final response = await http.get(Uri.parse(url));
      final json = convert.jsonDecode(response.body);
      if (json['predictions'] != null) {
        return (json['predictions'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
