# Generate Random Transactions

Synthetic transaction data for testing and for calibrating thresholds
against what mining finds in noise.

## Usage

``` r
random_transactions(
  n_transactions,
  n_items,
  density = 0.2,
  item_prefix = "item",
  prob = NULL
)
```

## Arguments

- n_transactions:

  Number of transactions.

- n_items:

  Number of distinct items.

- density:

  Probability that any given item appears in any given transaction.
  Default `0.2`.

- item_prefix:

  Prefix for generated item labels. Default `"item"`.

- prob:

  Optional per-item probability vector overriding `density`.

## Value

A `dyna_transactions` object.

## See also

[`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)

## Examples

``` r
set.seed(1)
random_transactions(20, 5, density = 0.4)
#> <dyna_transactions>  20 transactions | 5 items | unit: row
#>   set form only (binary matrix input; sequential mining unavailable)
```
