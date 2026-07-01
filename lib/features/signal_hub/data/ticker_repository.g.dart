// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticker_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tickerRepositoryHash() => r'6bd0c5c21fea91d8b565cc25761405e19f926adb';

/// See also [tickerRepository].
@ProviderFor(tickerRepository)
final tickerRepositoryProvider = AutoDisposeProvider<TickerRepository>.internal(
  tickerRepository,
  name: r'tickerRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tickerRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TickerRepositoryRef = AutoDisposeProviderRef<TickerRepository>;
String _$tickerQuotesHash() => r'aeb197d47f39d20a1f27f1fda69cc442db1d6897';

/// See also [tickerQuotes].
@ProviderFor(tickerQuotes)
final tickerQuotesProvider =
    AutoDisposeFutureProvider<Map<String, TickerQuote>>.internal(
      tickerQuotes,
      name: r'tickerQuotesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$tickerQuotesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TickerQuotesRef =
    AutoDisposeFutureProviderRef<Map<String, TickerQuote>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
