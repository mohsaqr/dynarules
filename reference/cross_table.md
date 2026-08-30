# Pairwise Item Co-Occurrence

The cross table of every item pair, in tidy long form rather than as a
matrix.

## Usage

``` r
cross_table(x, measure = c("count", "support", "lift"), diagonal = FALSE)
```

## Arguments

- x:

  A `dyna_transactions` object, or anything
  [`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)
  accepts.

- measure:

  `"count"` (default) for the number of transactions holding both items,
  `"support"` for that as a fraction, or `"lift"` for the ratio of joint
  to expected support.

- diagonal:

  Logical; keep the item-with-itself rows. Default `FALSE`. For
  `measure = "lift"` those rows are `NA`: an item's lift against itself
  is not defined.

## Value

A tidy `data.frame`: `item1`, `item2`, `value`.

## See also

[`item_frequency()`](https://mohsaqr.github.io/dynarules/reference/item_frequency.md),
[`affinity()`](https://mohsaqr.github.io/dynarules/reference/affinity.md)

## Examples

``` r
tr <- transactions(list(c("a", "b"), c("a", "c"), c("a", "b", "c")))
cross_table(tr)
#>   item1 item2 value
#> 1     a     b     2
#> 2     a     c     2
#> 3     b     a     2
#> 4     c     a     2
#> 5     b     c     1
#> 6     c     b     1
cross_table(tr, measure = "lift")
#>   item1 item2 value
#> 1     a     b  1.00
#> 2     a     c  1.00
#> 3     b     a  1.00
#> 4     c     a  1.00
#> 5     b     c  0.75
#> 6     c     b  0.75
```
