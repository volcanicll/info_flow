// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subscriptionStoreHash() => r'9f2623602cb97b37388972d48c3f6a2a18371297';

/// 订阅状态：持久化用户已订阅的源 id 集合
///
/// 订阅页切换、关注 tab 取源均依赖此 provider。
/// 首次安装时用默认源初始化，之后完全由用户控制。
///
/// Copied from [SubscriptionStore].
@ProviderFor(SubscriptionStore)
final subscriptionStoreProvider =
    NotifierProvider<SubscriptionStore, Set<String>>.internal(
      SubscriptionStore.new,
      name: r'subscriptionStoreProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$subscriptionStoreHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SubscriptionStore = Notifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
