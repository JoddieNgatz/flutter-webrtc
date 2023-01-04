// ignore: avoid_web_libraries_in_flutter
// import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
// //import 'dart:io';
// import 'dart:math';

class SimpleWebSocket {
  String _url;
  String _token;
  var _socket;
  Function() onOpen;
  Function(dynamic msg) onMessage;
  Function(int code, String reason) onClose;

  SimpleWebSocket(this._url, this._token) {
    _url = _url.replaceAll('https:', 'wss:');
  }

  connect() async {
    try {
      print(_token);
      _url = '$_url?from=web&config=$_token';
      print(_url);
      _socket = WebSocket(_url);
      _socket.onOpen.listen((e) {
        onOpen.call();
      });

      _socket.onMessage.listen((e) {
        onMessage.call(e.data);
      });

      _socket.onClose.listen((e) {
        onClose.call(e.code, e.reason);
      });
    } catch (e) {
      onClose.call(500, e.toString());
    }
  }

  send(data) {
    if (_socket != null && _socket.readyState == WebSocket.OPEN) {
      _socket.send(data);
      print('websocket connected send: $data');
    } else {
      print('WebSocket not connected, message $data not sent');
    }
  }

  // send(data) {
  //   if (_socket != null) {
  //     _socket.add(data);
  //   }
  // }

  close() {
    if (_socket != null) {
      _socket.close();
    }
  }
}
