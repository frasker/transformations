import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:transformations/transformations.dart';

void main() {
  test('Transformations', () {
    ValueNotifier<int> source = ValueNotifier(4);

    var map = Transformations.map(source, (n) {
      return "test$n";
    });

    map.addListener(() {
      print("new value : ${map.value}");
    });

    source.value = 3;

    source.value = 4;

    source.value = 5;
  });
}
