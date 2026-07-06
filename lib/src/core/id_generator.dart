class IdGenerator {
  int _counter = 0;

  String next(String prefix) {
    _counter += 1;
    final now = DateTime.now().microsecondsSinceEpoch;
    return '$prefix-$now-$_counter';
  }
}
