# Build a Classifier From Association Rules

Mines rules whose consequent is a class label, then reduces them to an
ordered decision list with the CBA M1 algorithm.

## Usage

``` r
cba(x, class, min_support = 0.05, min_confidence = 0.5, max_length = 5L, ...)
```

## Arguments

- x:

  A `dyna_transactions` object, or anything
  [`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)
  accepts.

- class:

  Character vector naming the items that are class labels, e.g.
  `c("pass", "fail")`. Every transaction must contain exactly one of
  them.

- min_support, min_confidence, max_length:

  Passed to
  [`dynarules()`](https://mohsaqr.github.io/dynarules/reference/dynarules.md)
  for the rule-mining step.

- ...:

  Further arguments for
  [`dynarules()`](https://mohsaqr.github.io/dynarules/reference/dynarules.md).

## Value

An object of class `dynarules_cba`: the ordered `rules`, the `default`
class, and the training `accuracy`.

## References

Liu, B., Hsu, W. and Ma, Y. (1998). Integrating classification and
association rule mining. *KDD-98*, 80–86.

## See also

[`dynarules()`](https://mohsaqr.github.io/dynarules/reference/dynarules.md),
[`rules()`](https://mohsaqr.github.io/dynarules/reference/rules.md)

## Examples

``` r
tx <- list(c("hot", "humid", "no"), c("hot", "windy", "no"),
           c("mild", "humid", "yes"), c("cool", "windy", "yes"),
           c("cool", "humid", "yes"), c("mild", "windy", "no"))
fit <- cba(tx, class = c("yes", "no"), min_support = 0.2,
           min_confidence = 0.5)
fit
#> <dynarules_cba>  3 rules | default: yes | classes: yes, no
#>   training accuracy: 1.000 on 6 transactions
#> 
#>   Decision list (first match wins):
#>      1. {hot} => no   conf=1.00  supp=0.33
#>      2. {cool} => yes   conf=1.00  supp=0.33
#>      3. {windy} => no   conf=0.67  supp=0.33
#>     --. otherwise => yes
predict(fit, tx)
#> [1] "no"  "no"  "yes" "yes" "yes" "no" 
```
