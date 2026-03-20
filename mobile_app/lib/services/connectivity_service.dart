import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnSvc {
  static final ConnSvc _i = ConnSvc._();
  factory ConnSvc() => _i;
  ConnSvc._();

  final _ctrl = StreamController<bool>.broadcast();
  Stream<bool> get stream => _ctrl.stream;
  bool _online = true;
  bool get online => _online;

  void init() {
    Connectivity().onConnectivityChanged.listen((res) {
      _online = res.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);
      _ctrl.add(_online);
    });
  }

  Future<bool> check() async {
    final res = await Connectivity().checkConnectivity();
    _online = res.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
    return _online;
  }
}
