import 'dart:async';

import '../game_server_handler.dart';

class Logger extends Handler {
  Logger(
    Function(Message) sendToClient,
    Function(Message) sendToServer,
  ) : super(sendToClient, sendToServer) {}

  Future handleClientMessage(Message message) async {
    // if (message is UnknownMessage) {
    //   print(message);
    // }
  }
}
