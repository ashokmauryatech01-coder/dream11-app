import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String token = '7e6097d77280407b05b3a124507e1c69';

  print('--- UPCOMING MATCHES ---');
  final url = Uri.parse(
    'https://restapi.entitysport.com/v2/matches?token=$token&status=1&per_page=50',
  );
  try {
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final items = (data['response']['items'] as List);
      print('Found ${items.length} upcoming matches:');
      for (var m in items) {
        print(
          ' - ID: ${m['match_id']}, Title: ${m['title']}, Comp: ${m['competition']['title']} (CID: ${m['competition']['cid']})',
        );
      }
    } else {
      print('Failed: ${res.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
