# Item Frequencies

Item Frequencies

## Usage

``` r
item_frequency(x, top = NULL)
```

## Arguments

- x:

  A `dyna_transactions` object, or anything
  [`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)
  accepts.

- top:

  Optional integer; keep only the `top` most frequent items.

## Value

A tidy `data.frame`: `item`, `count`, `support`, ordered by descending
support.

## See also

[`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md),
[`cross_table()`](https://mohsaqr.github.io/dynarules/reference/cross_table.md)

## Examples

``` r
tr <- transactions(list(c("a", "b"), c("a", "c"), c("a", "b", "c")))
item_frequency(tr)
#>   item count   support
#> 1    a     3 1.0000000
#> 2    b     2 0.6666667
#> 3    c     2 0.6666667
```
