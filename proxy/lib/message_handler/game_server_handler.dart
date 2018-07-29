import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'handlers/logger.dart';
import 'handlers/triple_ability.dart';

final _clientRcv = new ReceivePort();
final _serverRcv = new ReceivePort();
SendPort _ctrlSend;
SendPort _clientSend;
SendPort _serverSend;

final handlers = new List<Handler>();

main(args, List<SendPort> ports) {
  print('Starting up connection handler...');
  _ctrlSend = ports[0];
  _clientSend = ports[1];
  _serverSend = ports[2];

  _clientRcv.listen((data) => onClientData(data));
  _serverRcv.listen((data) => onServerData(data));

  _ctrlSend.send([_clientRcv.sendPort, _serverRcv.sendPort]);

  handlers.addAll([
    new TripleAbility(
        (Message data) => _clientSend.send(data.toNetworkMessage()),
        (Message data) => _serverSend.send(data.toNetworkMessage())),
    new Logger((Message data) => _clientSend.send(data.toNetworkMessage()),
        (Message data) => _serverSend.send(data.toNetworkMessage()))
  ]);
}

Future<void> onClientData(List<int> data) async {
  final msg = Message.fromData(data);
  try {
    await Future.wait(handlers.map((h) => h.handleClientMessage(msg)));

    // if (msg is JumpMessage) {
    //   //print('JUMP: ${msg.isJumping}');
    // } else if (msg is ChangeAbilityMessage) {
    //   //print('ABILITY: ${msg.ability}');
    // } else if (msg is PositionMessage) {
    //   // print(
    //   //     'POS: ${msg.x}, ${msg.y}, ${msg.z} (rotate: ${msg.rotationX}, ${msg.rotationY})');
    // } else {
    //   print(msg);
    // }
    //print(data);
  } catch (e) {
    // TODO: Can we make this output better (eg. red)?
    // stderr.add here crashes
    print(e);
  } finally {
    if (!msg.intercepted) {
      _serverSend.send(data);
    }
  }
}

Future<void> onServerData(List<int> data) async {
  // try {
  _clientSend.send(data);
  // } catch (e) {
  //   // TODO: Can we make this output better (eg. red)?
  //   // stderr.add here crashes
  //   print(e);
  //   _clientSend.send(data);
  // }
}

abstract class Message {
  bool get intercepted => _intercepted;
  bool _intercepted;
  ByteData _originalMessage;
  ByteData get originalMessage => _originalMessage;

  Message(this._originalMessage);

  static Message fromData(List<int> data) {
    final byteData = new Uint8List.fromList(data).buffer.asByteData();
    // TODO: Stop passing raw data in (when we can construct messages ourselves).
    if (PositionMessage.isMessage(byteData)) {
      return new PositionMessage(byteData);
    }
    if (JumpMessage.isMessage(byteData)) {
      return new JumpMessage(byteData);
    }
    if (ChangeAbilityMessage.isMessage(byteData)) {
      return new ChangeAbilityMessage(byteData);
    }
    if (UseAbilityMessage.isMessage(byteData)) {
      return new UseAbilityMessage(byteData);
    }
    return new UnknownMessage(byteData);
  }

  void markIntercepted() {
    _intercepted = true;
  }

  List<int> toNetworkMessage() {
    return _originalMessage.buffer.asUint8List();
  }
}

class UnknownMessage extends Message {
  UnknownMessage(ByteData data) : super(data);

  String toString() {
    final commandId = _originalMessage.getUint16(0, Endian.little);
    final messageIndexes =
        new List<int>.generate(originalMessage.lengthInBytes - 2, (i) => i + 2);
    final message = new String.fromCharCodes(
        messageIndexes.map((i) => _originalMessage.getUint8(i)));
    return '??? 0x${commandId.toRadixString(16)} ${_originalMessage.buffer.asUint8List()}\n'
        '    $message';
  }
}

class PositionMessage extends Message {
  double x, y, z, rotationX, rotationY, velocity;
  static bool isMessage(ByteData data) {
    return data.lengthInBytes >= 22 &&
        data.getInt16(0, Endian.little) == 0x766D;
  }

  PositionMessage(ByteData data) : super(data);

  _parse(ByteData data) {
    x = data.getFloat32(2, Endian.little);
    y = data.getFloat32(6, Endian.little);
    z = data.getFloat32(10, Endian.little);
    rotationX = new ByteData.view(
            new Uint8List.fromList([0, 0, 0, data.getUint8(14)]).buffer)
        .getFloat32(0, Endian.little);
    // (6d, 76,)
    //rotationY = data.buffer.asByteData(16, 2).getFloat32(0, Endian.little);
    // velocity = data.getFloat16(18, Endian.little);
    // 2x CommandID
    // 4x X pos
    // 4x Y pos
    // 4x Z pos
    // ???
    // ???
    // ???
    // ???
    // 0 ???
    // 0 ???
    // forwards/backwards (127 / 129) ???
    // left/riht (12 / 129) ???
    // print(new List<int>.generate(8, (i) => i)
    //  .map((i) => data.getUint8(14 + i).toRadixString(16)));
  }
}

class JumpMessage extends PositionMessage {
  bool get isJumping => _isJumping;
  bool _isJumping;
  static bool isMessage(ByteData data) {
    return data.lengthInBytes >= 3 && data.getInt16(0, Endian.little) == 0x706A;
  }

  JumpMessage(ByteData data) : super(data) {
    _parse(data);
  }

  _parse(ByteData data) {
    _isJumping = data.getInt8(2) == 1;
    super._parse(new ByteData.view(data.buffer, 3));
  }
}

class ChangeAbilityMessage extends PositionMessage {
  int get ability => _ability;
  int _ability;
  static bool isMessage(ByteData data) {
    return data.lengthInBytes >= 3 && data.getInt16(0, Endian.little) == 0x3D73;
  }

  ChangeAbilityMessage(ByteData data) : super(data) {
    _parse(data);
  }

  _parse(ByteData data) {
    _ability = data.getInt8(2);
    super._parse(new ByteData.view(data.buffer, 3));
  }
}

class UseAbilityMessage extends PositionMessage {
  String get abilityName => _abilityName;
  String _abilityName;
  int get unknownProjectileTypeOrAbilityId => _unknownProjectileTypeOrAbilityId;
  int _unknownProjectileTypeOrAbilityId;
  static bool isMessage(ByteData data) {
    return data.lengthInBytes >= 3 && data.getInt16(0, Endian.little) == 0x692A;
  }

  UseAbilityMessage(ByteData data) : super(data) {
    _parse(data);
  }

  _parse(ByteData data) {
    final nameLength = data.getInt16(2, Endian.little);
    final nameIndexes = new List<int>.generate(nameLength, (i) => i + 4);
    _abilityName =
        new String.fromCharCodes(nameIndexes.map((i) => data.getUint8(i)));
    _unknownProjectileTypeOrAbilityId = data.getUint8(nameIndexes.last + 1);
    // print(new List<int>.generate(13, (i) => i + nameIndexes.last + 1)
    //     .map((i) => data.getUint8(i).toRadixString(16))
    //     .toList());
    super._parse(new ByteData.view(data.buffer, 2 + nameLength + 13));
  }
}

// 27762
// RELOAD
// (Unknown command 27762?): [114, 108, 109, 118, 219, 92, 46, 71, 134, 112, 0, 71, 176, 246, 24, 68, 18, 3, 18, 208, 0, 0, 0, 0]

abstract class Handler {
  Function(Message) sendToClient;
  Function(Message) sendToServer;

  Handler(this.sendToClient, this.sendToServer);

  Future handleClientMessage(Message message) async {}
  Future handleServerMessage(Message message) async {}
}
