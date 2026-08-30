# Extract, Filter, and Rank Mined Rules

The tidy accessor for a mined rule set. All narrowing and ordering is
done through arguments; the returned data.frame is printed directly.

## Usage

``` r
rules(
  x,
  min_support = 0,
  min_confidence = 0,
  min_lift = 0,
  items = NULL,
  side = c("any", "antecedent", "consequent"),
  redundant = TRUE,
  significant = FALSE,
  maximal = FALSE,
  alpha = 0.05,
  adjust = "BH",
  top = NULL,
  by = c("lift", "confidence", "support")
)
```

## Arguments

- x:

  A `dynarules` object.

- min_support, min_confidence, min_lift:

  Numeric. Tighten the corresponding threshold post hoc (defaults keep
  everything mined).

- items:

  Character or NULL. Keep only rules mentioning at least one of these
  items on the chosen `side`.

- side:

  Character. Where `items` must appear: `"any"` (default),
  `"antecedent"`, or `"consequent"`.

- redundant:

  Logical. `TRUE` (default) keeps all rules. `FALSE` drops rules
  dominated by a more general rule: same consequent, the general
  antecedent contained in the specific one, and confidence at least as
  high.

- significant:

  Keep only rules that beat independence; see
  [`is_significant()`](https://mohsaqr.github.io/dynarules/reference/is_significant.md).
  Default `FALSE`.

- maximal:

  Keep only rules built on a maximal pattern; see
  [`is_maximal()`](https://mohsaqr.github.io/dynarules/reference/is_maximal.md).
  Default `FALSE`.

- alpha, adjust:

  Passed to
  [`is_significant()`](https://mohsaqr.github.io/dynarules/reference/is_significant.md)
  when `significant = TRUE`.

- top:

  Integer or NULL. Keep the top N rules after sorting.

- by:

  Character. Sort key: `"lift"` (default), `"confidence"`, or
  `"support"`. Descending, confidence as tie-break.

## Value

A tidy data.frame, one row per rule (same columns as `x$rules`).

## Examples

``` r
trans <- list(c("plan", "discuss", "reflect"),
              c("plan", "discuss", "execute"),
              c("plan", "reflect"),
              c("discuss", "reflect"))
fit <- dynarules(trans, min_support = 0.25, min_lift = 0)
rules(fit, min_lift = 1, top = 5)
#>         antecedent    consequent support confidence     lift conviction
#> 1          execute discuss, plan    0.25        1.0 2.000000        Inf
#> 2    discuss, plan       execute    0.25        0.5 2.000000        1.5
#> 3          execute       discuss    0.25        1.0 1.333333        Inf
#> 4          execute          plan    0.25        1.0 1.333333        Inf
#> 5 discuss, execute          plan    0.25        1.0 1.333333        Inf
#>   support_antecedent support_consequent count n_transactions
#> 1               0.25               0.50     1              4
#> 2               0.50               0.25     1              4
#> 3               0.25               0.75     1              4
#> 4               0.25               0.75     1              4
#> 5               0.25               0.75     1              4
```
