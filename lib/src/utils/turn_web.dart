import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map> getTurnCredential(String host, String token) async {
  host = '$host&from=web&config=$token';
  print(host);
  final res = await http.get(Uri.parse(host));
  print('Get token response: ${res.statusCode}');
  if (res.statusCode == 200) {
    var data = json.decode(res.body);
    print('getTurnCredential:response => $data.');
    return data;
  }
  return {};
}

Future<String> getToken(String url, String username, String password) async {
  try {
    var body = json.encode({"username": "$username", "password": "$password"});
    print(Uri.parse(url));
    final res = await http.post(
      Uri.https('*serverurl*:8086', '/login'),
      body: body,
    );
    var data = json.decode(res.body);
    print('getToken:response => ${res.statusCode}');
    return data['access_token'];
  } catch (e) {
    print(e);
    return e.toString();
  }
  
}
