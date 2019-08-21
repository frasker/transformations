# transformations

transformations 是一个转化 ValueNotifier 的工具类，实现数据监听的流转

## 如何使用

```
    ValueNotifier<int> source = ValueNotifier(4);

    var newValueNotifier = Transformations.map(source, (n) {
      return "test$n";
    });

    newValueNotifier.addListener(() {
      print("new value : ${newValueNotifier.value}");
    });

    source.value = 3;

    source.value = 4;

    source.value = 5;
```
## 如何依赖
请依赖github
```
   transformations:
    git:
        url: https://github.com/frasker/transformations
        ref: 1.0.0-alpha2