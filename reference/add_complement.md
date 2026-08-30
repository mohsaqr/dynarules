# Add Complement Items

Adds a negated item for each named item, so rules can be mined about the
*absence* of a behaviour as well as its presence.

## Usage

``` r
add_complement(x, items = NULL, prefix = "!")
```

## Arguments

- x:

  A `dyna_transactions` object, or anything
  [`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)
  accepts.

- items:

  Character vector of items to complement. Defaults to all items.

- prefix:

  Prefix for the complement labels. Default `"!"`.

## Value

A `dyna_transactions` object with the complement items added. Sequences
are dropped, because the absence of an item has no position in a
sequence.

## See also

[`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)

## Examples

``` r
tr <- transactions(list(c("a", "b"), c("a"), c("b")))
add_complement(tr, items = "a")
#> <dyna_transactions>  3 transactions | 3 items | unit: given
#>   set form only (binary matrix input; sequential mining unavailable)
```
