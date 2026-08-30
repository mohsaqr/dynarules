# Roll Items Up a Hierarchy

Replaces items by the group they belong to, so mining runs at a coarser
level of description (individual actions to action categories, say).

## Usage

``` r
aggregate_items(x, hierarchy)
```

## Arguments

- x:

  A `dyna_transactions` object, or anything
  [`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)
  accepts.

- hierarchy:

  A named character vector mapping item to group, or a two-column
  `data.frame` (`item`, `group`). Items absent from the map keep their
  own label.

## Value

A `dyna_transactions` object at the group level. Sequence order is
preserved; runs of the same group collapse to a single event.

## See also

[`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)

## Examples

``` r
tr <- transactions(list(c("read", "quiz"), c("video", "quiz")))
aggregate_items(tr, c(read = "study", video = "study", quiz = "assess"))
#> <dyna_transactions>  2 transactions | 2 items | unit: given
#>   mean events per transaction: 2.0 (ordered sequences kept)
```
