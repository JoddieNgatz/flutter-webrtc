import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<Map> getTurnCredential(String host, String token) async {
  print('turn web $token');
  final res = await http
      .get(Uri.parse(host), headers: {"Authorization": 'Bearer $token'});

  var data = json.decode(res.body);
  print('getTurnCredential:response => $data.');
  return data;
}

Future<String> getToken(String url, String username, String password) async {
  try {
    var body = {"username": "$username", "password": "$password"};
    HttpClient client = HttpClient(context: SecurityContext());
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return true;
    };

    var request = await client.postUrl(Uri.parse(url));
    request.headers.set('content-type', 'application/json');
    request.add(utf8.encode(json.encode(body)));
    var response = await request.close();
    var responseBody = await response.transform(Utf8Decoder()).join();
    Map data = JsonDecoder().convert(responseBody);
    return data['access_token'];
  } catch (e) {
    // print(e);
    return e.toString();
  }
}
