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
  static final int START_VERSION = -1;
  int _mActiveCount = 0;
  bool _mDispatchingValue = false;
  bool _mDispatchInvalidated = false;
  int _mVersion = START_VERSION;
  SafeIterableMap<ValueNotifier, _Source> _mSources = new SafeIterableMap();
  SafeIterableMap<VoidCallback, _ObserverWrapper<T>> _mObservers =
      new SafeIterableMap<VoidCallback, _ObserverWrapper<T>>();

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
    if (hasActiveObservers()) {
      e.plug();
    }
  }

  void removeSource<S>(ValueNotifier<S> toRemote) {
    _Source source = _mSources.remove(toRemote);
    if (source != null) {
      source.unplug();
    }
  }

  @override
  set value(T newValue) {
    _mVersion++;
    super.value = newValue;
    _dispatchingValue(null);
  }

  void onActive() {
    for (MapEntry<ValueNotifier, _Source> source in _mSources) {
      source.value.plug();
    }
  }

  void onInactive() {
    for (MapEntry<ValueNotifier, _Source> source in _mSources) {
      source.value.unplug();
    }
  }

  @override
  void addListener(listener) {
    _AlwaysActiveObserver<T> wrapper =
        new _AlwaysActiveObserver<T>(this, listener);
    _ObserverWrapper existing = _mObservers.putIfAbsent(listener, wrapper);
    if (existing != null) {
      throw new Exception("Cannot add the same listener");
    }
    if (existing != null) {
      return;
    }
    wrapper.activeStateChanged(true);
  }

  @override
  void removeListener(listener) {
    _ObserverWrapper removed = _mObservers.remove(listener);
    if (removed == null) {
      return;
    }
    removed.activeStateChanged(false);
  }

  bool hasObservers() {
    return _mObservers.length > 0;
  }

  bool hasActiveObservers() {
    return _mActiveCount > 0;
  }

  void _dispatchingValue(_ObserverWrapper<T> initiator) {
    if (_mDispatchingValue) {
      _mDispatchInvalidated = true;
      return;
    }
    _mDispatchingValue = true;
    do {
      _mDispatchInvalidated = false;
      if (initiator != null) {
        _considerNotify(initiator);
        initiator = null;
      } else {
        IteratorWithAdditions<VoidCallback, _ObserverWrapper<T>> iterator =
            _mObservers.iteratorWithAdditions();
        while (iterator.moveNext()) {
          _considerNotify(iterator.current.value);
          if (_mDispatchInvalidated) {
            break;
          }
        }
      }
    } while (_mDispatchInvalidated);
    _mDispatchingValue = false;
  }

  void _considerNotify(_ObserverWrapper<T> observer) {
    if (!observer.mActive) {
      return;
    }
    if (!observer.shouldBeActive()) {
      observer.activeStateChanged(false);
      return;
    }
    if (observer.mLastVersion >= _mVersion) {
      return;
    }
    observer.mLastVersion = _mVersion;
    observer.mObserver();
  }
}

abstract class _ObserverWrapper<T> {
  final MediatorValueNotifier<T> mValueNotifierData;
  final VoidCallback mObserver;
  bool mActive = false;
  int mLastVersion = MediatorValueNotifier.START_VERSION;

  _ObserverWrapper(this.mValueNotifierData, this.mObserver);

  bool shouldBeActive();

  void activeStateChanged(bool newActive) {
    if (newActive == mActive) {
      return;
    }
    // immediately set active state, so we'd never dispatch anything to inactive
    // owner
    mActive = newActive;
    bool wasInactive = mValueNotifierData._mActiveCount == 0;
    mValueNotifierData._mActiveCount += mActive ? 1 : -1;
    if (wasInactive && mActive) {
      mValueNotifierData.onActive();
    }
    if (mValueNotifierData._mActiveCount == 0 && !mActive) {
      mValueNotifierData.onInactive();
    }
    if (mActive) {
      mValueNotifierData._dispatchingValue(this);
    }
  }
}

class _AlwaysActiveObserver<T> extends _ObserverWrapper<T> {
  _AlwaysActiveObserver(MediatorValueNotifier<T> owner, VoidCallback observer)
      : super(owner, observer);

  @override
  bool shouldBeActive() {
    return true;
  }
}

class _Source<V> {
  final ValueNotifier<V> mValueNotifier;
  final VoidCallback mObserver;

  _Source(this.mValueNotifier, this.mObserver);

  void plug() {
    mValueNotifier.addListener(onChanged);

    /// 源头是ValueNotifier时，addListener并不会触发通知，所以这里手动触发
    if (!(mValueNotifier is MediatorValueNotifier)) {
      onChanged();
    }
  }

  void unplug() {
    mValueNotifier.removeListener(onChanged);
  }

  void onChanged() {
    mObserver();
  }
}
