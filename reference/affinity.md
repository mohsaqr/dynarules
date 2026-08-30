# Item Affinity

Jaccard similarity between every pair of items: how often they occur
together relative to how often either occurs at all.

## Usage

``` r
affinity(x)
```

## Arguments

- x:

  A `dyna_transactions` object, or anything
  [`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)
  accepts.

## Value

A tidy `data.frame`: `item1`, `item2`, `affinity`.

## See also

[`cross_table()`](https://mohsaqr.github.io/dynarules/reference/cross_table.md)

## Examples

``` r
tr <- transactions(list(c("a", "b"), c("a", "c"), c("a", "b", "c")))
affinity(tr)
#>   item1 item2  affinity
#> 1     a     b 0.6666667
#> 2     a     c 0.6666667
#> 3     b     a 0.6666667
#> 4     c     a 0.6666667
#> 5     b     c 0.3333333
#> 6     c     b 0.3333333
```
