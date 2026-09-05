// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticker_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tickerRepository)
final tickerRepositoryProvider = TickerRepositoryProvider._();

final class TickerRepositoryProvider
    extends
        $FunctionalProvider<
          TickerRepository,
          TickerRepository,
          TickerRepository
        >
    with $Provider<TickerRepository> {
  TickerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tickerRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tickerRepositoryHash();

  @$internal
  @override
  $ProviderElement<TickerRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TickerRepository create(Ref ref) {
    return tickerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TickerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TickerRepository>(value),
    );
  }
}

String _$tickerRepositoryHash() => r'c10ea9937aaa4d498ebe507ed99a0fbe7a506aa3';

@ProviderFor(tickerQuotes)
final tickerQuotesProvider = TickerQuotesProvider._();

final class TickerQuotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, TickerQuote>>,
          Map<String, TickerQuote>,
          FutureOr<Map<String, TickerQuote>>
        >
    with
        $FutureModifier<Map<String, TickerQuote>>,
        $FutureProvider<Map<String, TickerQuote>> {
  TickerQuotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tickerQuotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tickerQuotesHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, TickerQuote>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, TickerQuote>> create(Ref ref) {
    return tickerQuotes(ref);
  }
}

String _$tickerQuotesHash() => r'ab0674fb2c915ec5e6f0d7ab2b131088e2507881';
