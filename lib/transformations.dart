library transformations;

import 'package:flutter/foundation.dart';
import 'map.dart';

class Transformations {
  static ValueNotifier<Y> map<X, Y>(
      ValueNotifier<X> source, Y mapFunction(X x)) {
    final MediatorValueNotifier<Y> result = new MediatorValueNotifier<Y>();
    result.addSource(source, () {
      result.value = mapFunction(source.value);
    });
    return result;
  }

  static ValueNotifier<Y> switchMap<X, Y>(
      ValueNotifier<X> source, ValueNotifier<Y> switchMapFunction(X source)) {
    final MediatorValueNotifier<Y> result = new MediatorValueNotifier<Y>();
    ValueNotifier<Y> mSource;
    result.addSource(source, () {
      ValueNotifier<Y> newValueNotifier = switchMapFunction(source.value);
      if (mSource == newValueNotifier) {
        return;
      }
      if (mSource != null) {
        result.removeSource(mSource);
      }
      mSource = newValueNotifier;
      if (mSource != null) {
        result.addSource(mSource, () {
          result.value = mSource.value;
        });
      }
    });
    return result;
  }
}

class MediatorValueNotifier<T> extends ValueNotifier<T> {
  SafeIterableMap<ValueNotifier, _Source> _mSources = new SafeIterableMap();

  MediatorValueNotifier() : super(null);

  void addSource<S>(ValueNotifier<S> source, VoidCallback onChanged) {
    _Source<S> e = new _Source<S>(source, onChanged);
    _Source existing = _mSources.putIfAbsent(source, e);
    if (existing != null && existing.mObserver != onChanged) {
      throw new Exception(
          "This source was already added with the different observer");
    }
    if (existing != null) {
      return;
    }
    e.plug();
  }

  void removeSource<S>(ValueNotifier<S> toRemote) {
    _Source source = _mSources.remove(toRemote);
    if (source != null) {
      source.unplug();
    }
  }
}

class _Source<V> {
  final ValueNotifier<V> mValueNotifier;
  final VoidCallback mObserver;

  _Source(this.mValueNotifier, this.mObserver);

  void plug() {
    mValueNotifier.addListener(mObserver);
  }

  void unplug() {
    mValueNotifier.removeListener(mObserver);
  }
}
