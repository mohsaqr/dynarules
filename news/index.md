# Changelog

## dynarules 0.5.0

### Naming

- `discretize()` is now
  [`discretize_items()`](https://mohsaqr.github.io/dynarules/reference/discretize_items.md).
  The bare name collided with both `arules::discretize()` and
  `tsn::discretize()` – and tsn’s is a different operation on a
  different input shape (long time-series data, fifteen methods, states
  rather than items), so masking it would have been actively confusing.
  The new name also says what the verb is for. dynarules now collides
  with no name in `cograph`, `Nestimate` or `tsn`.

### Sequential constraints

- [`dynarules()`](https://mohsaqr.github.io/dynarules/reference/dynarules.md)
  gains `gap`, `min_gap` and `window_size` for sequential mining: the
  maximum and minimum number of events between consecutive items of a
  pattern, and the maximum span from a pattern’s first item to its last.
  Gaps are counted in events, not clock time.

- The containment matcher now backtracks. Unconstrained, a greedy
  first-match scan is exact; under a maximum gap it is not, because
  committing to the earliest occurrence can strand the rest of the
  pattern past the limit when a later occurrence would have matched. The
  constrained path carries the full set of reachable positions instead.
  Verified against a brute-force enumeration of every embedding: 4000
  random trials, zero disagreements.

- Mining with a maximum gap disables the drop-one subsequence prune,
  which is not valid under that constraint: dropping an item from the
  middle of a pattern widens the gap between its neighbours, so a
  frequent pattern can have an infrequent drop-one subsequence. The GSP
  join itself is unaffected, since dropping the first or last item never
  widens an interior gap.

### Rule induction

- [`rule_induction()`](https://mohsaqr.github.io/dynarules/reference/rule_induction.md)
  regenerates rules from patterns already mined, at new confidence,
  lift, length or `appearance` thresholds, without re-running the miner.
  Output is identical to re-mining, for both rule types. `min_support`
  cannot be lowered this way – patterns below the original threshold
  were never counted.

### Classification

- [`cba()`](https://mohsaqr.github.io/dynarules/reference/cba.md) builds
  a classifier from class association rules using the CBA M1 algorithm
  (Liu, Hsu & Ma 1998): rules are sorted by precedence and reduced to an
  ordered decision list, keeping a rule only when it correctly
  classifies a case not already covered, with the default class and
  cut-off chosen to minimise total error.

- [`predict()`](https://rdrr.io/r/stats/predict.html) for
  `dynarules_cba` returns predicted classes, or with `type = "rule"` the
  index of the rule that fired.

- [`print()`](https://rdrr.io/r/base/print.html) and
  [`summary()`](https://rdrr.io/r/base/summary.html) methods show the
  decision list.

### Verified against arulesSequences

- Unconstrained sequential mining and `gap = 1` match
  `arulesSequences::cspade()` exactly, once the definitions are aligned
  (cspade counts sequences, dynarules counts transactions).

- `window_size` does **not** correspond to cspade’s `maxwin`, and no
  constant offset aligns them. dynarules therefore makes no
  window-parity claim; its own definition is the brute-force-verified
  one above.

## dynarules 0.4.0

- Networks are rendered by cograph. `plot(type = "graph")` hands the
  object to
  [`cograph::splot()`](https://sonsoles.me/cograph/reference/splot.html)
  through the `meta$splot` producer contract instead of drawing its own
  layout. The `grid` dependency is gone.

- [`as_network()`](https://mohsaqr.github.io/dynarules/reference/as_network.md)
  gains `level = "rule"`, the standard association-rule graph with one
  node per rule. It keeps the conjunction the item-level collapse loses:
  under `level = "item"`, `{a,b} => c` is indistinguishable from
  `a => c` plus `b => c`.

- [`as_network()`](https://mohsaqr.github.io/dynarules/reference/as_network.md)
  accepts any of the 50 interest measures as `weight`.

- Directedness is derived rather than assumed. Sequential rules are
  always directed; co-occurrence rules only when the weight is
  asymmetric. Confidence, conviction and Laplace accuracy are
  asymmetric; lift, support, kappa, jaccard, cosine, phi and leverage
  are symmetric, so a lift-weighted co-occurrence network is undirected.

- [`rule_key()`](https://mohsaqr.github.io/dynarules/reference/rule_key.md)
  draws the size and colour key for a rule-level network.

## dynarules 0.3.0

- Transaction layer:
  [`item_frequency()`](https://mohsaqr.github.io/dynarules/reference/item_frequency.md),
  [`cross_table()`](https://mohsaqr.github.io/dynarules/reference/cross_table.md),
  [`affinity()`](https://mohsaqr.github.io/dynarules/reference/affinity.md),
  [`support_of()`](https://mohsaqr.github.io/dynarules/reference/support_of.md),
  [`sample_transactions()`](https://mohsaqr.github.io/dynarules/reference/sample_transactions.md),
  [`random_transactions()`](https://mohsaqr.github.io/dynarules/reference/random_transactions.md),
  [`add_complement()`](https://mohsaqr.github.io/dynarules/reference/add_complement.md),
  [`aggregate_items()`](https://mohsaqr.github.io/dynarules/reference/aggregate_items.md),
  [`read_transactions()`](https://mohsaqr.github.io/dynarules/reference/read_transactions.md).

- [`discretize_items()`](https://mohsaqr.github.io/dynarules/reference/discretize_items.md)
  for numeric vectors and data.frames, with frequency, interval, cluster
  and fixed methods.

- Weighted support: `transactions(weights =)` and
  `dynarules(weights =)`. Support becomes the share of total weight
  rather than of transactions.

- Verified against arules: weighted support matches `weclat()`, all
  transaction verbs match their arules counterparts, and
  [`discretize_items()`](https://mohsaqr.github.io/dynarules/reference/discretize_items.md)
  matches on all four methods.

## dynarules 0.2.0

- All 50 scalar interest measures via
  [`measures()`](https://mohsaqr.github.io/dynarules/reference/measures.md),
  catalogued by
  [`list_measures()`](https://mohsaqr.github.io/dynarules/reference/list_measures.md),
  each verified identical to `arules::interestMeasure()`.

- [`itemsets()`](https://mohsaqr.github.io/dynarules/reference/itemsets.md)
  with the four condensed targets: frequent, closed, maximal and
  generator.

- [`is_redundant()`](https://mohsaqr.github.io/dynarules/reference/is_redundant.md),
  [`is_significant()`](https://mohsaqr.github.io/dynarules/reference/is_significant.md)
  and
  [`is_maximal()`](https://mohsaqr.github.io/dynarules/reference/is_maximal.md),
  also available as arguments to
  [`rules()`](https://mohsaqr.github.io/dynarules/reference/rules.md).

- Six plot types via `plot(type =)`.

- [`dynarules()`](https://mohsaqr.github.io/dynarules/reference/dynarules.md)
  gains `min_length` and `appearance`.

## dynarules 0.1.0

- First release. Co-occurrence Apriori and sequential GSP mining over an
  explicit event-log transaction grammar (actor, action, time, session,
  window), with tidy post-hoc verbs, network conversion, bootstrap
  stability and permutation significance testing.
