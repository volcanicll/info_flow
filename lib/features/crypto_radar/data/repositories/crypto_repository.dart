import '../datasources/binance_api.dart';
import '../models/pool_item.dart';
import '../models/oi_alert.dart';
import '../models/trade_signal.dart';

class _Kline {
  final double open, high, low, close, vol;
  const _Kline({required this.open, required this.high, required this.low, required this.close, required this.vol});
}

class CryptoRepository {
  final BinanceApi _api;
  CryptoRepository(this._api);

  void Function(String message)? onProgress;

  static const int minSidewaysDays = 45;
  static const double maxRangePct = 80;
  static const double maxAvgVolUsd = 20000000;
  static const double minOiDeltaPct = 3.0;
  static const double minOiUsd = 2000000;
  static const double volBreakoutMult = 3.0;

  double _n(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  // ── Accumulation Pool ──

  Future<List<PoolItem>> scanAccumulationPool() async {
    final symbols = await _api.getAllPerpSymbols();
    final results = <PoolItem>[];
    for (var i = 0; i < symbols.length; i++) {
      final klines = await _api.getKlines(symbols[i]);
      if (klines != null) {
        final r = _analyzeAccumulation(symbols[i], klines);
        if (r != null) results.add(r);
      }
      if ((i + 1) % 10 == 0) await Future.delayed(const Duration(milliseconds: 500));
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  PoolItem? _analyzeAccumulation(String symbol, List<List<dynamic>> klines) {
    if (klines.length < 50) return null;
    final data = klines.map((k) => _Kline(
      open: _n(k[1]), high: _n(k[2]), low: _n(k[3]), close: _n(k[4]), vol: _n(k[7]),
    )).toList();
    final coin = symbol.replaceAll('USDT', '');
    const exclude = {'USDC', 'USDP', 'TUSD', 'FDUSD', 'BTCDOM', 'DEFI', 'USDM'};
    if (exclude.contains(coin)) return null;

    final recent7d = data.sublist(data.length - 7);
    final prior = data.sublist(0, data.length - 7);
    if (prior.isEmpty) return null;

    final recentAvgPx = recent7d.fold(0.0, (s, d) => s + d.close) / recent7d.length;
    final priorAvgPx = prior.fold(0.0, (s, d) => s + d.close) / prior.length;
    if (priorAvgPx > 0 && (recentAvgPx - priorAvgPx) / priorAvgPx > 3.0) return null;

    int bestSideways = 0;
    double bestRange = 0, bestLow = 0, bestHigh = 0, bestAvgVol = 0, bestSlopePct = 0;

    for (var window = minSidewaysDays; window <= prior.length; window++) {
      final w = prior.sublist(prior.length - window);
      final wLow = w.map((d) => d.low).reduce((a, b) => a < b ? a : b);
      final wHigh = w.map((d) => d.high).reduce((a, b) => a > b ? a : b);
      if (wLow <= 0) continue;
      final rangePct = ((wHigh - wLow) / wLow) * 100;
      if (rangePct <= maxRangePct) {
        final avgVol = w.fold(0.0, (s, d) => s + d.vol) / w.length;
        if (avgVol <= maxAvgVolUsd) {
          final closes = w.map((d) => d.close).toList();
          final n = closes.length;
          final xMean = (n - 1) / 2.0;
          final yMean = closes.fold(0.0, (s, c) => s + c) / n;
          double num = 0, den = 0;
          for (var i = 0; i < n; i++) {
            num += (i - xMean) * (closes[i] - yMean);
            den += (i - xMean) * (i - xMean);
          }
          final slope = den > 0 ? num / den : 0.0;
          final slopePct = closes[0] > 0 ? (slope * n / closes[0] * 100) : 0.0;
          if (slopePct.abs() > 20) continue;
          if (window > bestSideways) {
            bestSideways = window;
            bestRange = rangePct;
            bestLow = wLow;
            bestHigh = wHigh;
            bestAvgVol = avgVol;
            bestSlopePct = slopePct;
          }
        }
      }
    }
    if (bestSideways < minSidewaysDays) return null;

    final daysScore = (bestSideways / 90).clamp(0.0, 1.0) * 25;
    final rangeScore = (1 - bestRange / maxRangePct).clamp(0.0, 1.0) * 20;
    final volScore = (1 - bestAvgVol / maxAvgVolUsd).clamp(0.0, 1.0) * 20;
    final recentVol = recent7d.fold(0.0, (s, d) => s + d.vol) / recent7d.length;
    final volBreakout = bestAvgVol > 0 ? recentVol / bestAvgVol : 0.0;
    final breakoutScore = (volBreakout / volBreakoutMult).clamp(0.0, 1.0) * 15;
    final currentPrice = data.last.close;
    final estMcap = currentPrice * bestAvgVol * 30;

    double mcapScore;
    if (estMcap > 0 && estMcap < 50000000) { mcapScore = 20; }
    else if (estMcap < 100000000) { mcapScore = 15; }
    else if (estMcap < 200000000) { mcapScore = 10; }
    else if (estMcap < 500000000) { mcapScore = 5; }
    else { mcapScore = 0; }

    double totalScore = daysScore + rangeScore + volScore + breakoutScore + mcapScore;
    totalScore += (1 - bestSlopePct.abs() / 20).clamp(0.0, 1.0) * 5;

    String status;
    if (volBreakout >= volBreakoutMult) { status = '🔥放量启动'; }
    else if (volBreakout >= 1.5) { status = '⚡开始放量'; }
    else { status = '💤收筹中'; }

    return PoolItem(
      symbol: symbol, coin: coin,
      sidewaysDays: bestSideways, rangePct: bestRange, slopePct: bestSlopePct,
      lowPrice: bestLow, highPrice: bestHigh,
      avgVol: bestAvgVol, currentPrice: currentPrice,
      recentVol: recentVol, volBreakout: volBreakout,
      score: totalScore, status: status,
    );
  }

  // ── OI Scan ──

  Future<List<OiAlert>> scanOiChanges(Set<String> watchlist) async {
    final alerts = <OiAlert>[];
    for (final sym in watchlist) {
      final oiHist = await _api.getOpenInterestHist(sym, limit: 3);
      if (oiHist == null || oiHist.length < 2) continue;
      final prevOi = _n(oiHist[oiHist.length - 2]['sumOpenInterestValue']);
      final currOi = _n(oiHist.last['sumOpenInterestValue']);
      if (prevOi <= 0 || currOi < minOiUsd) continue;
      final deltaPct = ((currOi - prevOi) / prevOi) * 100;
      if (deltaPct.abs() >= minOiDeltaPct) {
        final ticker = await _api.getTicker24hSingle(sym);
        if (ticker == null) continue;
        final price = _n(ticker['lastPrice']);
        final vol24h = _n(ticker['quoteVolume']);
        final pxChg = _n(ticker['priceChangePercent']);
        final funding = await _api.getFundingRate(sym, limit: 1);
        final fr = (funding != null && funding.isNotEmpty) ? _n(funding.first['fundingRate']) : 0.0;
        alerts.add(OiAlert(
          symbol: sym, coin: sym.replaceAll('USDT', ''),
          price: price, oiUsd: currOi, oiDeltaPct: deltaPct,
          oiDeltaUsd: currOi - prevOi, vol24h: vol24h,
          pxChgPct: pxChg, fundingRate: fr,
        ));
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    alerts.sort((a, b) => b.oiDeltaPct.abs().compareTo(a.oiDeltaPct.abs()));
    return alerts;
  }

  // ── Three Strategy Engine ──

  Future<ScanResult> scanSignals() async {
    onProgress?.call('获取市场数据…');
    final tickersRaw = await _api.getTicker24h();
    final premiumsRaw = await _api.getPremiumIndex();
    if (tickersRaw == null || premiumsRaw == null) return ScanResult.empty();

    final volSurgeCoins = <String>{};

    final tickerMap = <String, Map<String, double>>{};
    for (final t in tickersRaw) {
      final sym = t['symbol'] as String? ?? '';
      if (!sym.endsWith('USDT')) continue;
      tickerMap[sym] = {
        'px_chg': _n(t['priceChangePercent']),
        'vol': _n(t['quoteVolume']),
        'price': _n(t['lastPrice']),
      };
    }

    final fundingMap = <String, double>{};
    for (final p in premiumsRaw) {
      final sym = p['symbol'] as String? ?? '';
      if (!sym.endsWith('USDT')) continue;
      fundingMap[sym] = _n(p['lastFundingRate']);
    }

    final mcapMap = <String, double>{};
    onProgress?.call('获取市值数据…');
    try {
      final mcapResp = await _api.getBinanceMarketList();
      if (mcapResp != null) {
        for (final item in (mcapResp['data'] as List<dynamic>? ?? [])) {
          final m = item as Map;
          final name = m['name'] as String?;
          final mc = m['marketCap'];
          if (name != null && mc != null) mcapMap[name] = _n(mc);
        }
      }
    } catch (_) {}

    final heatMap = <String, double>{};
    final cgTrending = <String>{};
    try {
      final cg = await _api.getCoinGeckoTrending();
      if (cg != null) {
        for (final item in cg) {
          final coin = item['item'] as Map;
          final sym = (coin['symbol'] as String? ?? '').toUpperCase();
          final rank = (coin['score'] as int?) ?? 99;
          if (sym.isNotEmpty) {
            cgTrending.add(sym);
            heatMap[sym] = (heatMap[sym] ?? 0) + (50 - rank * 3).clamp(10, 50).toDouble();
          }
        }
      }
    } catch (_) {}

    for (final entry in tickerMap.entries) {
      final sym = entry.key;
      final tk = entry.value;
      final coin = sym.replaceAll('USDT', '');
      final vol24h = tk['vol']!;
      if (vol24h > 20000000) {
        onProgress?.call('分析放量: $coin');
        final kl = await _api.getKlines(sym, limit: 6);
        if (kl != null && kl.length >= 5) {
          double avg5d = 0;
          for (var i = 0; i < kl.length - 1; i++) avg5d += _n(kl[i][7]);
          avg5d /= (kl.length - 1);
          if (avg5d > 0) {
            final ratio = vol24h / avg5d;
            if (ratio >= 2.5) {
              volSurgeCoins.add(coin);
              heatMap[coin] = (heatMap[coin] ?? 0) + (ratio * 10).clamp(0, 50);
            }
          }
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    final dualHeat = cgTrending.intersection(volSurgeCoins);
    for (final coin in dualHeat) {
      heatMap[coin] = (heatMap[coin] ?? 0) + 20;
    }

    // OI scan (top 100)
    final topByVol = tickerMap.entries.toList()
      ..sort((a, b) => b.value['vol']!.compareTo(a.value['vol']!));
    final scanSyms = topByVol.take(100).map((e) => e.key).toSet();

    final oiMap = <String, Map<String, double>>{};
    int oiIdx = 0;
    for (final sym in scanSyms) {
      oiIdx++;
      onProgress?.call('扫描持仓: $oiIdx/100');
      final oiHist = await _api.getOpenInterestHist(sym, limit: 6);
      if (oiHist != null && oiHist.length >= 2) {
        final curr = _n(oiHist.last['sumOpenInterestValue']);
        final prev1h = _n(oiHist[oiHist.length - 2]['sumOpenInterestValue']);
        final prev6h = _n(oiHist.first['sumOpenInterestValue']);
        final d1h = prev1h > 0 ? ((curr - prev1h) / prev1h * 100) : 0.0;
        final d6h = prev6h > 0 ? ((curr - prev6h) / prev6h * 100) : 0.0;
        oiMap[sym] = {'oi_usd': curr, 'd1h': d1h, 'd6h': d6h};
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Build coin data
    final coinData = <String, CoinData>{};
    for (final sym in scanSyms) {
      final tk = tickerMap[sym];
      if (tk == null) continue;
      final oi = oiMap[sym] ?? {};
      final frPct = (fundingMap[sym] ?? 0) * 100;
      final coin = sym.replaceAll('USDT', '');
      final d6h = (oi['d6h'] ?? 0.0);
      final oiUsd = (oi['oi_usd'] ?? 0.0);
      final estMcap = mcapMap[coin] ?? (tk['vol']! * 0.3);
      coinData[sym] = CoinData(
        coin: coin, sym: sym,
        pxChg: tk['px_chg']!, vol: tk['vol']!,
        frPct: frPct, d6h: d6h,
        oiUsd: oiUsd, estMcap: estMcap,
        heat: heatMap[coin] ?? 0,
        inCg: cgTrending.contains(coin),
        volSurge: volSurgeCoins.contains(coin),
      );
    }

    // Strategy 1: Chase
    final chase = <TradeSignal>[];
    for (final entry in coinData.entries) {
      final d = entry.value;
      if (d.pxChg > 3 && d.frPct < -0.005 && d.vol > 1000000) {
        onProgress?.call('分析追多: ${d.coin}');
        final frHist = await _api.getFundingRate(entry.key, limit: 5);
        double frPrev = d.frPct;
        if (frHist != null && frHist.length >= 2) {
          frPrev = _n(frHist[frHist.length - 2]['fundingRate']) * 100;
        }
        final frDelta = d.frPct - frPrev;
        String trend;
        if (frDelta < -0.05) trend = '🔥加速';
        else if (frDelta < -0.01) trend = '⬇️变负';
        else if (frDelta.abs() < 0.01) trend = '➡️';
        else trend = '⬆️回升';

        final price = d.estMcap;
        final volPct = (d.pxChg.abs() * 1.2).clamp(5.0, 100.0);
        final slPct = volPct * 0.6;
        final tpPct = slPct * 3;
        final riskAmt = 2400 * 0.02;
        final margin = riskAmt / (slPct / 100 * 10);
        final score = (60 + d.frPct.abs() * 200).toInt().clamp(0, 100);

        chase.add(TradeSignal(
          coin: d.coin, sym: d.sym, direction: '🟢做多', score: score,
          strategy: '追多（费率极端）',
          price: price, entry: price, sl: price * (1 - slPct / 100),
          tp: price * (1 + tpPct / 100), slPct: slPct,
          margin: margin, notional: margin * 10, risk: riskAmt,
          tags: ['费${d.frPct.toStringAsFixed(3)}%', trend, '${d.pxChg.toInt()}%'],
          urgency: trend.contains('加速') ? '⭐⭐⭐' : '⭐⭐',
        ));
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    chase.sort((a, b) => b.score.compareTo(a.score));
    if (chase.length > 5) chase.removeRange(5, chase.length);

    // Strategy 2: Combined
    final combined = <TradeSignal>[];
    for (final d in coinData.values) {
      int fSc;
      if (d.frPct < -0.5) fSc = 25;
      else if (d.frPct < -0.1) fSc = 22;
      else if (d.frPct < -0.05) fSc = 18;
      else if (d.frPct < -0.03) fSc = 14;
      else if (d.frPct < -0.01) fSc = 10;
      else if (d.frPct < 0) fSc = 5;
      else fSc = 0;

      int mSc;
      if (d.estMcap > 0 && d.estMcap < 50e6) mSc = 25;
      else if (d.estMcap < 100e6) mSc = 22;
      else if (d.estMcap < 200e6) mSc = 20;
      else if (d.estMcap < 300e6) mSc = 17;
      else if (d.estMcap < 500e6) mSc = 12;
      else if (d.estMcap < 1e9) mSc = 7;
      else mSc = 0;

      final abs6 = d.d6h.abs();
      int oSc;
      if (abs6 >= 15) oSc = 25;
      else if (abs6 >= 8) oSc = 22;
      else if (abs6 >= 5) oSc = 18;
      else if (abs6 >= 3) oSc = 14;
      else if (abs6 >= 2) oSc = 10;
      else oSc = 0;

      final total = fSc + mSc + 0 + oSc;
      if (total < 25) continue;
      final price = d.estMcap;
      final volPct = (d.pxChg.abs() * 1.2).clamp(5.0, 100.0);
      final slPct = volPct * 0.6;
      final tpPct = slPct * 3;
      final riskAmt = 2400 * 0.02;
      final margin = riskAmt / (slPct / 100 * 10);

      final tags = <String>[];
      if (fSc >= 10) tags.add('费${d.frPct.toStringAsFixed(2)}%');
      if (mSc >= 12) tags.add('市值${formatUsd(d.estMcap)}');
      if (oSc >= 10) tags.add('OI${d.d6h.toStringAsFixed(0)}%');

      combined.add(TradeSignal(
        coin: d.coin, sym: d.sym, direction: '🟢做多', score: total,
        strategy: '综合（四维评分）',
        price: price, entry: price, sl: price * (1 - slPct / 100),
        tp: price * (1 + tpPct / 100), slPct: slPct,
        margin: margin, notional: margin * 10, risk: riskAmt,
        tags: tags, urgency: total >= 70 ? '⭐⭐' : '⭐',
      ));
    }
    combined.sort((a, b) => b.score.compareTo(a.score));
    if (combined.length > 3) combined.removeRange(3, combined.length);

    // Strategy 3: Ambush
    final ambush = <TradeSignal>[];
    for (final d in coinData.values) {
      int mSc;
      if (d.estMcap > 0 && d.estMcap < 50e6) mSc = 35;
      else if (d.estMcap < 100e6) mSc = 32;
      else if (d.estMcap < 150e6) mSc = 28;
      else if (d.estMcap < 200e6) mSc = 25;
      else if (d.estMcap < 300e6) mSc = 20;
      else if (d.estMcap < 500e6) mSc = 12;
      else if (d.estMcap < 1e9) mSc = 5;
      else mSc = 0;

      int oSc;
      final abs6 = d.d6h.abs();
      if (abs6 >= 10) oSc = 30;
      else if (abs6 >= 5) oSc = 25;
      else if (abs6 >= 3) oSc = 20;
      else if (abs6 >= 2) oSc = 14;
      else if (abs6 >= 1) oSc = 8;
      else oSc = 0;
      if (d.d6h > 2 && d.pxChg.abs() < 5) oSc = (oSc + 5).clamp(0, 30);

      int fSc;
      if (d.frPct < -0.1) fSc = 15;
      else if (d.frPct < -0.05) fSc = 12;
      else if (d.frPct < -0.03) fSc = 9;
      else if (d.frPct < -0.01) fSc = 6;
      else if (d.frPct < 0) fSc = 3;
      else fSc = 0;

      final total = mSc + oSc + 0 + fSc;
      if (total < 20) continue;

      final price = d.estMcap;
      final volPct = (d.pxChg.abs() * 1.5).clamp(5.0, 100.0);
      final slPct = volPct * 0.6;
      final tpPct = slPct * 3;
      final riskAmt = 2400 * 0.02;
      final margin = riskAmt / (slPct / 100 * 10);
      final direction = d.d6h > 0 || d.frPct < 0 ? '🟢做多' : '🔴做空';
      final tags = <String>[formatUsd(d.estMcap)];
      if (d.d6h.abs() >= 2) tags.add('OI${d.d6h.toStringAsFixed(0)}%');

      ambush.add(TradeSignal(
        coin: d.coin, sym: d.sym, direction: direction, score: total,
        strategy: '埋伏（低市值+OI异动）',
        price: price, entry: price, sl: price * (1 - slPct / 100),
        tp: price * (1 + tpPct / 100), slPct: slPct,
        margin: margin, notional: margin * 10, risk: riskAmt,
        tags: tags,
        urgency: total >= 80 ? '⭐⭐⭐' : total >= 60 ? '⭐⭐' : '⭐',
      ));
    }
    ambush.sort((a, b) => b.score.compareTo(a.score));
    if (ambush.length > 5) ambush.removeRange(5, ambush.length);

    // Heat
    final heatList = coinData.values.where((d) => d.heat > 0).toList()
      ..sort((a, b) => b.heat.compareTo(a.heat));

    // Highlights
    final highlights = <String>[];
    final signalCoins = {...chase.map((s) => s.coin), ...combined.map((s) => s.coin)};
    if (ambush.isNotEmpty) {
      highlights.add('🎯 ${ambush.first.coin} OI异动+低市值');
    }
    final chaseCoins = chase.take(10).map((s) => s.coin).toSet();
    final combinedCoins = combined.take(10).map((s) => s.coin).toSet();
    for (final c in chaseCoins.intersection(combinedCoins).take(2)) {
      if (signalCoins.contains(c)) highlights.add('⭐ $c 追多+综合双榜共振');
    }

    return ScanResult(
      chase: chase, combined: combined, ambush: ambush,
      heat: heatList.take(6).toList(),
      highlights: highlights,
    );
  }

  static String formatUsd(double v) {
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(0)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }
}

class CoinData {
  final String coin, sym;
  final double pxChg, vol, frPct, d6h, oiUsd, estMcap, heat;
  final bool inCg, volSurge;
  const CoinData({
    required this.coin, required this.sym,
    required this.pxChg, required this.vol,
    required this.frPct, required this.d6h,
    required this.oiUsd, required this.estMcap,
    this.heat = 0, this.inCg = false, this.volSurge = false,
  });
}

class ScanResult {
  final List<TradeSignal> chase, combined, ambush;
  final List<CoinData> heat;
  final List<String> highlights;
  const ScanResult({
    required this.chase, required this.combined, required this.ambush,
    required this.heat, required this.highlights,
  });
  static ScanResult empty() => const ScanResult(
    chase: [], combined: [], ambush: [], heat: [], highlights: [],
  );
}
