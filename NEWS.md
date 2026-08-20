# dynarules 0.5.0

## Sequential constraints

* `dynarules()` gains `gap`, `min_gap` and `window_size` for sequential
  mining: the maximum and minimum number of events between consecutive
  items of a pattern, and the maximum span from a pattern's first item to
  its last. Gaps are counted in events, not clock time.

* The containment matcher now backtracks. Unconstrained, a greedy
  first-match scan is exact; under a maximum gap it is not, because
  committing to the earliest occurrence can strand the rest of the pattern
  past the limit when a later occurrence would have matched. The
  constrained path carries the full set of reachable positions instead.
  Verified against a brute-force enumeration of every embedding: 4000
  random trials, zero disagreements.

* Mining with a maximum gap disables the drop-one subsequence prune, which
  is not valid under that constraint: dropping an item from the middle of
  a pattern widens the gap between its neighbours, so a frequent pattern
  can have an infrequent drop-one subsequence. The GSP join itself is
  unaffected, since dropping the first or last item never widens an
  interior gap.

## Rule induction

* `rule_induction()` regenerates rules from patterns already mined, at new
  confidence, lift, length or `appearance` thresholds, without re-running
  the miner. Output is identical to re-mining, for both rule types.
  `min_support` cannot be lowered this way -- patterns below the original
  threshold were never counted.

## Classification

* `cba()` builds a classifier from class association rules using the CBA
  M1 algorithm (Liu, Hsu & Ma 1998): rules are sorted by precedence and
  reduced to an ordered decision list, keeping a rule only when it
  correctly classifies a case not already covered, with the default class
  and cut-off chosen to minimise total error.

* `predict()` for `dynarules_cba` returns predicted classes, or with
  `type = "rule"` the index of the rule that fired.

* `print()` and `summary()` methods show the decision list.

## Verified against arulesSequences

* Unconstrained sequential mining and `gap = 1` match
  `arulesSequences::cspade()` exactly, once the definitions are aligned
  (cspade counts sequences, dynarules counts transactions).

* `window_size` does **not** correspond to cspade's `maxwin`, and no
  constant offset aligns them. dynarules therefore makes no window-parity
  claim; its own definition is the brute-force-verified one above.


# dynarules 0.4.0

* Networks are rendered by cograph. `plot(type = "graph")` hands the
  object to `cograph::splot()` through the `meta$splot` producer contract
  instead of drawing its own layout. The `grid` dependency is gone.

* `as_network()` gains `level = "rule"`, the standard association-rule
  graph with one node per rule. It keeps the conjunction the item-level
  collapse loses: under `level = "item"`, `{a,b} => c` is
  indistinguishable from `a => c` plus `b => c`.

* `as_network()` accepts any of the 50 interest measures as `weight`.

* Directedness is derived rather than assumed. Sequential rules are always
  directed; co-occurrence rules only when the weight is asymmetric.
  Confidence, conviction and Laplace accuracy are asymmetric; lift,
  support, kappa, jaccard, cosine, phi and leverage are symmetric, so a
  lift-weighted co-occurrence network is undirected.

* `rule_key()` draws the size and colour key for a rule-level network.


# dynarules 0.3.0

* Transaction layer: `item_frequency()`, `cross_table()`, `affinity()`,
  `support_of()`, `sample_transactions()`, `random_transactions()`,
  `add_complement()`, `aggregate_items()`, `read_transactions()`.

* `discretize()` for numeric vectors and data.frames, with frequency,
  interval, cluster and fixed methods.

* Weighted support: `transactions(weights =)` and `dynarules(weights =)`.
  Support becomes the share of total weight rather than of transactions.

* Verified against arules: weighted support matches `weclat()`, all
  transaction verbs match their arules counterparts, and `discretize()`
  matches on all four methods.


# dynarules 0.2.0

* All 50 scalar interest measures via `measures()`, catalogued by
  `list_measures()`, each verified identical to
  `arules::interestMeasure()`.

* `itemsets()` with the four condensed targets: frequent, closed, maximal
  and generator.

* `is_redundant()`, `is_significant()` and `is_maximal()`, also available
  as arguments to `rules()`.

* Six plot types via `plot(type =)`.

* `dynarules()` gains `min_length` and `appearance`.


# dynarules 0.1.0

* First release. Co-occurrence Apriori and sequential GSP mining over an
  explicit event-log transaction grammar (actor, action, time, session,
  window), with tidy post-hoc verbs, network conversion, bootstrap
  stability and permutation significance testing.
