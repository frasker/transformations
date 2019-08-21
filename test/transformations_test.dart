import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:transformations/transformations.dart';

void main() {
  test('Transformations', () {
    ValueNotifier<int> source = ValueNotifier(12);

    var map = Transformations.map(source, (n) {
      return "test$n";
    });


    var map1 = Transformations.switchMap(map, (n) {
      return ValueNotifier("eeeeeee   $n");
    });

    map1.addListener(() {
      print("new value : ${map1.value}");
    });


    source.value = 3;


    source.value = 56;

    source.value = 5;
  });
}
