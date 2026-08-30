# Sample Transactions

Sample Transactions

## Usage

``` r
sample_transactions(x, size = NULL, replace = FALSE, prob = NULL)
```

## Arguments

- x:

  A `dyna_transactions` object, or anything
  [`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)
  accepts.

- size:

  Number of transactions to draw. Defaults to all of them.

- replace:

  Sample with replacement? Default `FALSE`.

- prob:

  Optional sampling probabilities, one per transaction.

## Value

A `dyna_transactions` object holding the sampled transactions.

## See also

[`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md),
[`bootstrap_rules()`](https://mohsaqr.github.io/dynarules/reference/bootstrap_rules.md)

## Examples

``` r
tr <- transactions(list(c("a", "b"), c("a", "c"), c("a", "b", "c")))
sample_transactions(tr, size = 2)
#> <dyna_transactions>  2 transactions | 3 items | unit: given
#>   mean events per transaction: 2.5 (ordered sequences kept)
```
