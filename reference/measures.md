# Interest Measures for Mined Rules

Computes any of the 51 association-rule interest measures for a mined
rule set. Call
[`list_measures()`](https://mohsaqr.github.io/dynarules/reference/list_measures.md)
for the catalogue.

## Usage

``` r
measures(x, measure = NULL, counts = FALSE)
```

## Arguments

- x:

  A `dynarules` object.

- measure:

  Character vector of measure names, or `NULL` (the default) for the
  four headline measures: support, confidence, lift and count. Use
  `"all"` for the entire catalogue.

- counts:

  Logical; when `TRUE`, also return the four contingency counts (`n11`,
  `n10`, `n01`, `n00`) — the equivalent of the `table` measure in other
  implementations. Defaults to `FALSE`.

## Value

A tidy `data.frame` with one row per rule: `antecedent`, `consequent`,
then one column per requested measure.

## Details

All measures are functions of the number of transactions and the three
supports P(A), P(B) and P(A and B), which together fix the rule's 2x2
contingency table. `improvement`, `boost`, `LIC` and `importance`
additionally compare each rule against the most favourable more general
rule (same consequent, a proper sub-antecedent); they are `NA` -free by
falling back to the independence baseline when the antecedent is a
single item.

For sequential rules the 2x2 table is an approximation: the support of
`A -> B` counts only occurrences in the right order, so it can fall
below the co-occurrence of `A` and `B` and leave the implied table
inconsistent. When that happens `measures()` warns once and the affected
contingency measures return `NA`; support, confidence and lift are
unaffected.

## See also

[`list_measures()`](https://mohsaqr.github.io/dynarules/reference/list_measures.md),
[`rules()`](https://mohsaqr.github.io/dynarules/reference/rules.md)

## Examples

``` r
fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
                 min_support = 0.3, min_confidence = 0.3)
measures(fit)
#>   antecedent consequent   support confidence lift count
#> 1          b          a 0.6666667  1.0000000    1     2
#> 2          c          a 0.6666667  1.0000000    1     2
#> 3       b, c          a 0.3333333  1.0000000    1     1
#> 4          a          b 0.6666667  0.6666667    1     2
#> 5          a          c 0.6666667  0.6666667    1     2
#> 6          a       b, c 0.3333333  0.3333333    1     1
measures(fit, measure = c("kappa", "phi", "jaccard"))
#>   antecedent consequent        kappa phi   jaccard
#> 1          b          a 0.000000e+00 NaN 0.6666667
#> 2          c          a 0.000000e+00 NaN 0.6666667
#> 3       b, c          a 8.326673e-17 NaN 0.3333333
#> 4          a          b 0.000000e+00 NaN 0.6666667
#> 5          a          c 0.000000e+00 NaN 0.6666667
#> 6          a       b, c 0.000000e+00 NaN 0.3333333
```
