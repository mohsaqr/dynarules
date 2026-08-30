# Induce Rules From Already-Mined Patterns

Regenerates the rule set from the frequent patterns of a fitted model,
at different thresholds, without re-mining the transactions.

## Usage

``` r
rule_induction(
  x,
  min_confidence = 0.5,
  min_lift = 1,
  min_length = NULL,
  max_length = NULL,
  appearance = NULL
)
```

## Arguments

- x:

  A `dynarules` object.

- min_confidence, min_lift:

  Thresholds for the induced rules.

- min_length, max_length:

  Optional bounds on the number of items in a rule. Default: those of
  the fitted model.

- appearance:

  Optional list restricting where items may occur, as in
  [`dynarules()`](https://mohsaqr.github.io/dynarules/reference/dynarules.md).
  `lhs` and `rhs` whitelist each side.

## Value

A `dynarules` object carrying the induced rules. Everything that works
on a mined model –
[`rules()`](https://mohsaqr.github.io/dynarules/reference/rules.md),
[`measures()`](https://mohsaqr.github.io/dynarules/reference/measures.md),
[`plot()`](https://rdrr.io/r/graphics/plot.default.html),
[`as_network()`](https://mohsaqr.github.io/dynarules/reference/as_network.md)
– works on it.

## Details

Mining is the expensive half; rule generation is a cheap split of each
frequent pattern. So exploring confidence or lift cut-offs, or
restricting which items may appear on each side, should not mean running
the miner again. `min_support` cannot be lowered here – the patterns
below the original support threshold were never counted, so recovering
them does require re-mining.

## See also

[`dynarules()`](https://mohsaqr.github.io/dynarules/reference/dynarules.md),
[`rules()`](https://mohsaqr.github.io/dynarules/reference/rules.md)

## Examples

``` r
fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
                 min_support = 0.3, min_confidence = 0.9)
nrow(rules(fit))
#> [1] 3
loose <- rule_induction(fit, min_confidence = 0.3)
nrow(rules(loose))
#> [1] 6
```
