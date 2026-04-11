import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String token1 = '7e6097d77280407b05b3a124507e1c69';
  const String token2 = 'ec471071441bb2ac538a0ff901abd249';
  
  await search('TOKEN 1', token1);
  await search('TOKEN 2', token2);
}

Future<void> search(String label, String token) async {
  print('--- SEARCHING WITH $label ---');
  final url = Uri.parse('https://restapi.entitysport.com/v2/competitions?token=$token&per_page=500');
  try {
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final items = (data['response']['items'] as List);
      final ipls = items.where((c) => c['title'].toString().toLowerCase().contains('ipl') || c['abbr'].toString().toLowerCase().contains('ipl')).toList();
      print('Found ${ipls.length} IPL competitions:');
      for (var ipl in ipls) {
        print(' - CID: ${ipl['cid']}, Title: ${ipl['title']}, Status: ${ipl['status']}, Season: ${ipl['season']}');
      }
    } else {
      print('Failed: ${res.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
