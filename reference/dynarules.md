# Mine Association or Sequential Rules

The single entry point for rule mining. `type = "cooccurrence"` mines
classic association rules (level-wise Apriori with full candidate
pruning): order within a transaction is ignored. `type = "sequential"`
mines order-aware rules (generalized sequential patterns): a rule
`plan -> discuss => reflect` states that transactions containing `plan`
followed (not necessarily immediately) by `discuss` tend to contain
`reflect` after both.

Accepts a ready
[`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)
object, or raw data plus the event-log grammar arguments, which are
forwarded to
[`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md).

## Usage

``` r
dynarules(
  x,
  type = c("cooccurrence", "sequential"),
  min_support = 0.1,
  min_confidence = 0.5,
  min_lift = 1,
  min_length = 2L,
  max_length = 5L,
  appearance = NULL,
  actor = NULL,
  action = NULL,
  time = NULL,
  session = NULL,
  unit = c("session", "actor", "window"),
  window = NULL,
  step = NULL,
  weights = NULL,
  gap = NULL,
  min_gap = NULL,
  window_size = NULL
)
```

## Arguments

- x:

  A `dyna_transactions` object, or raw data accepted by
  [`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)
  (long event log, wide data.frame, list, binary matrix).

- type:

  Character. `"cooccurrence"` (default) or `"sequential"`.

- min_support:

  Numeric, above 0 and at most 1. Minimum fraction of transactions
  containing the itemset/pattern. Default 0.1.

- min_confidence:

  Numeric between 0 and 1. Default 0.5.

- min_lift:

  Numeric \>= 0. Default 1.

- min_length:

  Integer. Minimum number of items in a rule (antecedent plus
  consequent). Default `2`.

- max_length:

  Integer \>= 2. Maximum itemset/pattern size. Default 5.

- appearance:

  Optional list restricting where items may occur: `lhs` and `rhs`
  whitelist the items allowed on each side, and `none` drops items from
  the data before mining. `NULL` (default) places no restriction.

- actor, action, time, session, unit, window, step:

  Event-log grammar, forwarded to
  [`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)
  when `x` is raw data.

- weights:

  Optional numeric vector of transaction weights, one per transaction.
  Support becomes weighted support: the share of total weight rather
  than the share of transactions. `NULL` (default) weights every
  transaction equally.

- gap:

  Maximum number of events allowed between consecutive items of a
  sequential pattern. `NULL` (default) places no limit, i.e. ordinary
  non-contiguous containment; `gap = 1` requires the items to be
  adjacent. Sequential mining only.

- min_gap:

  Minimum number of events between consecutive items. Sequential mining
  only.

- window_size:

  Maximum span, in events, from the first item of a pattern to its last.
  Sequential mining only. (Distinct from `window`, which cuts the
  transactions themselves.)

## Value

An object of class `"dynarules"`:

- rules:

  Tidy data.frame, one row per rule: antecedent, consequent, support,
  confidence, lift, conviction, count, n_transactions. Sequential
  antecedents/consequents use `" -> "` between ordered items;
  co-occurrence uses `", "`.

- frequent:

  Tidy data.frame of frequent itemsets/patterns.

- type, items, n_transactions, params:

  Metadata.

- transactions:

  The `dyna_transactions` object mined, kept so
  [`bootstrap_rules()`](https://mohsaqr.github.io/dynarules/reference/bootstrap_rules.md)
  and
  [`permute_rules()`](https://mohsaqr.github.io/dynarules/reference/permute_rules.md)
  can re-mine.

## Details

Support of a sequential pattern is the fraction of transactions whose
ordered sequence contains the pattern as a (not necessarily contiguous)
subsequence. Both miners use downward closure: every sub-itemset /
subsequence of a frequent set is itself frequent, which the candidate
pruning step exploits.

## See also

[`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md),
[`rules()`](https://mohsaqr.github.io/dynarules/reference/rules.md),
[`as_network()`](https://mohsaqr.github.io/dynarules/reference/as_network.md),
[`bootstrap_rules()`](https://mohsaqr.github.io/dynarules/reference/bootstrap_rules.md),
[`permute_rules()`](https://mohsaqr.github.io/dynarules/reference/permute_rules.md)

## Examples

``` r
log <- data.frame(
  student = rep(c("s1", "s2", "s3", "s4"), each = 3),
  code = c("plan", "discuss", "reflect",
           "plan", "discuss", "execute",
           "plan", "reflect", "discuss",
           "discuss", "plan", "reflect"),
  stringsAsFactors = FALSE
)
fit <- dynarules(log, actor = "student", action = "code",
                 type = "sequential", min_support = 0.25)
fit
#> <dynarules> sequential rules  [2 rules | 4 items | 4 transactions]
#>   support >= 0.25 | confidence >= 0.50 | lift >= 1.00 | max length 5
#> 
#>   Top rules (by lift):
#>      1. {discuss -> plan} => {reflect}  (sup=0.250 conf=1.000 lift=1.33)
#>      2. {plan} => {reflect}  (sup=0.750 conf=0.750 lift=1.00)
```
