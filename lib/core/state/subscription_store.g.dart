// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SubscriptionStore)
final subscriptionStoreProvider = SubscriptionStoreProvider._();

final class SubscriptionStoreProvider
    extends $NotifierProvider<SubscriptionStore, Set<String>> {
  SubscriptionStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionStoreHash();

  @$internal
  @override
  SubscriptionStore create() => SubscriptionStore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$subscriptionStoreHash() => r'c62b8e205538a023af733e16e4fcb252647f8e9f';

abstract class _$SubscriptionStore extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
