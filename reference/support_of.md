# Support of Arbitrary Itemsets

Support of itemsets you name yourself, without mining. Useful for
checking a hypothesis against the data directly.

## Usage

``` r
support_of(x, itemsets, type = c("cooccurrence", "sequential"))
```

## Arguments

- x:

  A `dyna_transactions` object, or anything
  [`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)
  accepts.

- itemsets:

  A character vector (one itemset) or a list of character vectors.

- type:

  `"cooccurrence"` (default) counts transactions containing all the
  items in any order; `"sequential"` requires them in the given order.

## Value

A tidy `data.frame`: `pattern`, `size`, `support`, `count`.

## See also

[`itemsets()`](https://mohsaqr.github.io/dynarules/reference/itemsets.md),
[`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)

## Examples

``` r
tr <- transactions(list(c("a", "b"), c("a", "c"), c("a", "b", "c")))
support_of(tr, list(c("a", "b"), c("b", "c"), "a"))
#>   pattern size   support count
#> 1    a, b    2 0.6666667     2
#> 2    b, c    2 0.3333333     1
#> 3       a    1 1.0000000     3
```
