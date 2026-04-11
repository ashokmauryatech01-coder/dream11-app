import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String token = '7e6097d77280407b05b3a124507e1c69';
  
  print('--- LISTING ALL COMPETITIONS FOR USER TOKEN ---');
  final url = Uri.parse('https://restapi.entitysport.com/v2/competitions/?token=$token&per_page=100');
  try {
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final items = (data['response']['items'] as List);
      print('Found ${items.length} competitions total:');
      for (var i in items) {
        print(' - CID: ${i['cid']}, Title: ${i['title']}, Abbr: ${i['abbr']}, Status: ${i['status']}');
      }
    } else {
      print('Failed: ${res.statusCode} - ${res.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
