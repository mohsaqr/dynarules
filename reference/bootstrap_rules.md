# Bootstrap Stability of Mined Rules

Assesses how reproducible each mined rule is under resampling.
Transactions are resampled with replacement `iter` times; each resample
is re-mined with the original thresholds. A rule's `recovery` is the
fraction of resamples in which it is rediscovered; its metric intervals
are percentile bootstrap CIs over the resamples that recovered it.

## Usage

``` r
bootstrap_rules(x, iter = 200L, conf = 0.95, seed = NULL)
```

## Arguments

- x:

  A `dynarules` object.

- iter:

  Integer. Number of bootstrap resamples. Default 200.

- conf:

  Numeric. CI coverage. Default 0.95.

- seed:

  Integer or NULL. Seed for reproducibility.

## Value

An object of class `"dynarules_boot"` with `$stability`, a tidy
data.frame (one row per original rule): antecedent, consequent,
recovery, and mean / lower / upper for support, confidence, and lift.

## References

Epskamp, S., Borsboom, D., & Fried, E. I. (2018). Estimating
psychological networks and their accuracy. *Behavior Research Methods*,
50, 195–212.

## Examples

``` r
trans <- list(c("plan", "discuss", "reflect"),
              c("plan", "discuss", "execute"),
              c("plan", "reflect"),
              c("discuss", "reflect"),
              c("plan", "discuss", "reflect"))
fit <- dynarules(trans, min_support = 0.3, min_lift = 0)
bs <- bootstrap_rules(fit, iter = 50, seed = 1)
bs
#> <dynarules_boot> 50 resamples | 12 rules | 95% CIs
#> 
#>   Rule stability (by recovery):
#>      1. {reflect} => {plan}  recovery=0.92  lift=0.95 [0.83, 1.00]
#>      2. {discuss} => {plan}  recovery=0.90  lift=0.97 [0.83, 1.00]
#>      3. {plan} => {discuss}  recovery=0.90  lift=0.97 [0.83, 1.00]
#>      4. {plan} => {reflect}  recovery=0.88  lift=0.95 [0.83, 1.00]
#>      5. {discuss} => {reflect}  recovery=0.84  lift=0.97 [0.83, 1.00]
#>      6. {reflect} => {discuss}  recovery=0.84  lift=0.97 [0.83, 1.00]
#>      7. {plan, reflect} => {discuss}  recovery=0.68  lift=0.96 [0.83, 1.00]
#>      8. {discuss, plan} => {reflect}  recovery=0.66  lift=0.93 [0.83, 1.00]
#>      9. {discuss, reflect} => {plan}  recovery=0.66  lift=0.92 [0.83, 1.00]
#>     10. {plan} => {discuss, reflect}  recovery=0.60  lift=0.91 [0.83, 1.00]
#>     ... and 2 more rules
```
