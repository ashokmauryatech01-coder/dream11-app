import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String token = '7e6097d77280407b05b3a124507e1c69';
  const String iplCid = '129908';
  
  print('--- AUDITING IPL MATCH STATUSES (CID $iplCid) ---');
  final url = Uri.parse('https://restapi.entitysport.com/v2/competitions/$iplCid/matches?token=$token&per_page=100');
  try {
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final items = (data['response']['items'] as List);
      print('Found ${items.length} matches:');
      for (var m in items) {
        print(' - ID: ${m['match_id']}, Title: ${m['title']}, Status: ${m['status']}, Date: ${m['date_start']}');
      }
    } else {
      print('Failed: ${res.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
