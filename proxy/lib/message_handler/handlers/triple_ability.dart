import 'dart:async';

import '../game_server_handler.dart';

/// This class toggles the ability to use an ability 3x with one key press.
/// To activate, just tap the number that switches to the ability twice quickly.
class TripleAbility extends Handler {
  bool _enabled = false;
  TripleAbility(
    Function(Message) sendToClient,
    Function(Message) sendToServer,
  ) : super(sendToClient, sendToServer) {}

  DateTime lastAbilityChange = new DateTime.now();
  int lastAbility;
  Future handleClientMessage(Message message) async {
    if (message is ChangeAbilityMessage) {
      if (message.ability == lastAbility &&
          new DateTime.now().difference(lastAbilityChange).inMilliseconds <
              500) {
        _enabled = true;
        // TODO: Tell user in chat!
        print('Enabled tripleAbility');
      } else if (message.ability != lastAbility) {
        _enabled = false;
      }
      lastAbilityChange = new DateTime.now();
      lastAbility = message.ability;
    }
    if (message is UseAbilityMessage) {
      // If enabled, send an extra two fireballs
      if (_enabled) {
        sendToServer(message);
        await new Future.delayed(const Duration(milliseconds: 500));
        sendToServer(message);
        await new Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }
}
