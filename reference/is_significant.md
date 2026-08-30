# Which Rules Beat Independence?

Tests each rule against the null that antecedent and consequent are
independent, using a one-sided Fisher's exact test on the rule's 2x2
contingency table, with multiplicity control across the rule set.

## Usage

``` r
is_significant(x, alpha = 0.05, adjust = "BH")
```

## Arguments

- x:

  A `dynarules` object.

- alpha:

  Significance level. Default `0.05`.

- adjust:

  Multiplicity correction, any method accepted by
  [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html). Default
  `"BH"`; use `"none"` to switch it off.

## Value

A logical vector with one entry per mined rule.

## Details

This is a test against *chance co-occurrence given the item margins*. It
is not the same question as
[`permute_rules()`](https://mohsaqr.github.io/dynarules/reference/permute_rules.md),
which asks whether a rule survives destroying the structure of the
transactions themselves; use that one when the transaction structure is
what you are arguing about.

## See also

[`rules()`](https://mohsaqr.github.io/dynarules/reference/rules.md),
[`permute_rules()`](https://mohsaqr.github.io/dynarules/reference/permute_rules.md),
[`measures()`](https://mohsaqr.github.io/dynarules/reference/measures.md)

## Examples

``` r
fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
                 min_support = 0.3, min_confidence = 0.3)
is_significant(fit)
#> [1] FALSE FALSE FALSE FALSE FALSE FALSE
```
