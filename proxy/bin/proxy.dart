import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'dart:isolate';

const String gameServer = "pwn3server.dantup.com";
const int masterServerPort = 3333;
const int startGameServerPort = 3000;
const int endGameServerPort = 3001;
final proxies = new List<Proxy>();
final handlerScript =
    new File('lib\\message_handler\\game_server_handler.dart').absolute;
final logFolder = new Directory('../logs').absolute;

main() async {
  proxies.add(new Proxy(gameServer, masterServerPort, 'master'));
  for (var port = startGameServerPort; port <= endGameServerPort; port++) {
    proxies.add(new Proxy(gameServer, port, 'game'));
  }
}

class Proxy {
  final connections = new List<ProxyConnection>();

  Proxy(String host, int port, String name) {
    ServerSocket
        .bind(InternetAddress.loopbackIPv4, port)
        .then((serverSocket) async {
      print('Listening on $port!');
      await for (final client in serverSocket) {
        print('Accepted connection on port $port from ${client.address}!');
        final server = await Socket.connect(host, port);
        connections.add(_connect(client, server, name));
      }
    });
  }

  ProxyConnection _connect(Socket client, Socket server, String name) {
    return new ProxyConnection(client, server, name);
  }
}

class ProxyConnection {
  Socket _client, _server;
  HandlerThread _currentHandlerThread;
  StreamController<HandlerThread> _handlerThreadCreated =
      new StreamController<HandlerThread>.broadcast();
  Timer isolateSpawnTimer;
  final logFiles = new Map<TrafficDirection, IOSink>();

  ProxyConnection(this._client, this._server, String logName) {
    if (logName != null) {
      logFiles[TrafficDirection.ClientToProxy] = _makeLog(logName, 'c2p');
      logFiles[TrafficDirection.ProxyToServer] = _makeLog(logName, 'p2s');
      logFiles[TrafficDirection.ServerToProxy] = _makeLog(logName, 's2p');
      logFiles[TrafficDirection.ProxyToClient] = _makeLog(logName, 'p2c');
    }

    _client.listen(handleClientPacket);
    _server.listen(handleServerPacket);

    handlerScript.parent
        .watch(events: FileSystemEvent.modify, recursive: true)
        .listen((FileSystemEvent e) {
      // Wait for 500ms before spawning new isolate to swallow repeat events
      if (isolateSpawnTimer != null && isolateSpawnTimer.isActive)
        isolateSpawnTimer.cancel();
      isolateSpawnTimer =
          new Timer(const Duration(milliseconds: 500), spawnNewIsolate);
    });

    _handlerThreadCreated.stream.listen((handlerThread) {
      final oldThread = _currentHandlerThread;
      _currentHandlerThread = handlerThread;
      if (oldThread != null) {
        print('Killing old isolate');
        oldThread.kill();
      }
    });

    spawnNewIsolate();
  }

  _makeLog(String name, String direction) {
    final file =
        new File(path.join(logFolder.path, 'proxy-$name-$direction.txt'));
    return file.openWrite();
  }

  final _start = new DateTime.now();
  _log(TrafficDirection dir, List<int> data) {
    final logFile = logFiles[dir];
    if (logFile != null) {
      final msElapsed = new DateTime.now().difference(_start).inMilliseconds;
      logFile.write('[ ${msElapsed.toString().padLeft(10)} ] ');
      logFile.writeln(data.map((b) => b.toRadixString(16)).join(' '));
    }
    return data;
  }

  Future<void> spawnNewIsolate() async {
    print('Spawning new isolate');

    try {
      final loggedClient = new StreamController<List<int>>()
        ..stream.listen((List<int> s) =>
            _client.add(_log(TrafficDirection.ProxyToClient, s)));
      final loggedServer = new StreamController<List<int>>()
        ..stream.listen((List<int> s) =>
            _server.add(_log(TrafficDirection.ProxyToServer, s)));

      final handlerThread =
          await HandlerThread.create(loggedClient, loggedServer);
      _handlerThreadCreated.add(handlerThread);
    } catch (e) {
      // TODO: Can we make this output better (eg. red)?
      // stderr.add here crashes?!
      print(e);
    }
  }

  handleClientPacket(List<int> data) {
    _log(TrafficDirection.ClientToProxy, data);

// If we have no handler thread, or it can't handle the message (it's not ready)
// then forward on.
    if (_currentHandlerThread == null ||
        !_currentHandlerThread.handleClientData(data)) {
      _server.add(data);
    }
  }

  handleServerPacket(List<int> data) {
    _log(TrafficDirection.ServerToProxy, data);

// If we have no handler thread, or it can't handle the message (it's not ready)
// then forward on.
    if (_currentHandlerThread == null ||
        !_currentHandlerThread.handleServerData(data)) {
      _client.add(data);
    }
  }
}

enum TrafficDirection {
  ClientToProxy,
  ProxyToServer,
  ServerToProxy,
  ProxyToClient,
}

class HandlerThread {
  Isolate _isolate;
  final _clientRcv = new ReceivePort();
  final _serverRcv = new ReceivePort();
  SendPort _clientSend, _serverSend;

  HandlerThread._();

  Future kill() async {
    // Give it 10 seconds to finish any async work before we queue a kill.
    await new Future.delayed(const Duration(seconds: 3));
    _isolate.kill();
  }

  bool handleClientData(List<int> data) {
    if (_clientSend != null) {
      _clientSend.send(data);
      return true;
    }
    return false;
  }

  bool handleServerData(List<int> data) {
    if (_serverSend != null) {
      _serverSend.send(data);
      return true;
    }
    return false;
  }

  static Future<HandlerThread> create(
      StreamSink<List<int>> client, StreamSink<List<int>> server) async {
    final handler = new HandlerThread._();

    final ctrlRcv = new ReceivePort();
    ctrlRcv.first.then((args) {
      handler._clientSend = args[0];
      handler._serverSend = args[1];
    });

    handler._clientRcv.listen(client.add);
    handler._serverRcv.listen(server.add);

    handler._isolate = await Isolate.spawnUri(handlerScript.uri, [], [
      ctrlRcv.sendPort,
      handler._clientRcv.sendPort,
      handler._serverRcv.sendPort
    ]);

    return handler;
  }
}
