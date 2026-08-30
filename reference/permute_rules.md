# Permutation Significance of Mined Rules

Tests each rule's lift against an explicit null. For co-occurrence rules
the null is item independence: each item column of the transaction
matrix is permuted independently, preserving every item's frequency
while destroying co-occurrence. For sequential rules the null is
order-irrelevance: the events *within* each transaction are shuffled,
preserving exactly which items co-occur while destroying their order –
so a significant sequential rule is informative *beyond* co-occurrence.

P-values are `(sum(lift_perm >= lift_obs) + 1) / (iter + 1)`.

## Usage

``` r
permute_rules(x, iter = 200L, correction = "BH", seed = NULL)
```

## Arguments

- x:

  A `dynarules` object.

- iter:

  Integer. Number of permutations. Default 200.

- correction:

  Character. Multiple-comparison correction passed to
  [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html). Default
  `"BH"`.

- seed:

  Integer or NULL. Seed for reproducibility.

## Value

An object of class `"dynarules_perm"` with `$tests`, a tidy data.frame
(one row per rule): antecedent, consequent, lift, lift_null (mean
permuted lift), p, p_adj, significant.

## Examples

``` r
trans <- list(c("plan", "discuss", "reflect"),
              c("plan", "discuss", "execute"),
              c("plan", "discuss", "reflect"),
              c("discuss", "reflect"))
fit <- dynarules(trans, min_support = 0.3, min_lift = 0)
pt <- permute_rules(fit, iter = 100, seed = 1)
pt
#> <dynarules_perm> 100 permutations | null: independent item-column permutation | BH correction
#>   0 of 12 rules significant at adjusted p < .05
#> 
#>   Rules (by adjusted p):
#>      1. {plan} => {discuss}  lift=1.00 (null 1.00)  p_adj=1.0000
#>      2. {reflect} => {discuss}  lift=1.00 (null 1.00)  p_adj=1.0000
#>      3. {plan, reflect} => {discuss}  lift=1.00 (null 1.00)  p_adj=1.0000
#>      4. {discuss} => {plan}  lift=1.00 (null 1.00)  p_adj=1.0000
#>      5. {discuss} => {reflect}  lift=1.00 (null 1.00)  p_adj=1.0000
#>      6. {discuss} => {plan, reflect}  lift=1.00 (null 1.00)  p_adj=1.0000
#>      7. {plan} => {reflect}  lift=0.89 (null 0.98)  p_adj=1.0000
#>      8. {reflect} => {plan}  lift=0.89 (null 0.98)  p_adj=1.0000
#>      9. {plan} => {discuss, reflect}  lift=0.89 (null 0.98)  p_adj=1.0000
#>     10. {reflect} => {discuss, plan}  lift=0.89 (null 0.98)  p_adj=1.0000
#>     ... and 2 more rules
```
