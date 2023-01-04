import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<Map> getTurnCredential(String host, String token) async {
  HttpClient client = HttpClient(context: SecurityContext());
  client.badCertificateCallback =
      (X509Certificate cert, String host, int port) {
    //   print('getTurnCredential: Allow self-signed certificate => $host:$port. ');
    return true;
  };
  var url = host;
  var request = await client.getUrl(Uri.parse(url));
  request.headers.add('Authorization', 'Bearer $token');
  var response = await request.close();
  var responseBody = await response.transform(Utf8Decoder()).join();
  // print('getTurnCredential:response => $responseBody.');
  Map data = JsonDecoder().convert(responseBody);
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



//   //Needs SSL
// Future<Map> getTurnCredential(String host, String token) async {
//   var url = host;
//   Map<String, String> headers = {};
//   headers.addAll({
//     "Authorization": 'Bearer $token',
//   });
//   dynamic request = await http.get(Uri.parse(url), headers: headers);
//   var response = await jsonDecode(request.body);
//   Map data = JsonDecoder().convert(response);
//   return data;
// }