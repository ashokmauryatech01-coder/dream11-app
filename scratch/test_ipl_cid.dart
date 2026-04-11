import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String token = '7e6097d77280407b05b3a124507e1c69';
  const String iplCid = '129908';
  
  print('--- CHECKING IPL CID ($iplCid) WITH USER TOKEN ---');
  final url = Uri.parse('https://restapi.entitysport.com/v2/competitions/$iplCid/matches/?token=$token');
  try {
    final res = await http.get(url);
    print('Response Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      print('API Status: ${data['status']}');
      if (data['status'] == 'ok') {
        final items = (data['response']['items'] as List);
        print('SUCCESS! Found ${items.length} matches for IPL CID 129908.');
      } else {
        print('API Error Message: ${data['response']}');
      }
    } else {
      print('HTTP Failure: ${res.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
