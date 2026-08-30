# Classify New Transactions

Classify New Transactions

## Usage

``` r
# S3 method for class 'dynarules_cba'
predict(object, newdata = NULL, type = c("class", "rule"), ...)
```

## Arguments

- object:

  A `dynarules_cba` classifier.

- newdata:

  Transactions to classify: a `dyna_transactions` object or anything
  [`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)
  accepts. Defaults to the training data.

- type:

  `"class"` (default) returns the predicted labels; `"rule"` returns the
  index of the rule that fired, `NA` where the default was used.

- ...:

  Ignored.

## Value

A character vector of predictions, or an integer vector of rule indices.

## See also

[`cba()`](https://mohsaqr.github.io/dynarules/reference/cba.md)

## Examples

``` r
tx <- list(c("hot", "humid", "no"), c("mild", "humid", "yes"),
           c("cool", "windy", "yes"), c("mild", "windy", "no"))
fit <- cba(tx, class = c("yes", "no"), min_support = 0.2,
           min_confidence = 0.5)
predict(fit, tx)
#> [1] "no"  "yes" "yes" "no" 
```
