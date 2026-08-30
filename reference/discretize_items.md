# Discretize a Numeric Variable Into Mining Items

Discretize a Numeric Variable Into Mining Items

## Usage

``` r
discretize_items(
  x,
  method = c("frequency", "interval", "cluster", "fixed"),
  breaks = 3,
  labels = NULL,
  include_lowest = TRUE,
  right = FALSE,
  ordered = FALSE,
  infinity = FALSE,
  ...
)
```

## Arguments

- x:

  A numeric vector, or a `data.frame` whose numeric columns are all to
  be discretized.

- method:

  How to place the cut points:

  - `"frequency"` (default) — equal-frequency bins (quantiles), so each
    bin holds roughly the same number of observations.

  - `"interval"` — equal-width bins across the observed range.

  - `"cluster"` — k-means on the values, cutting midway between adjacent
    cluster centres; bins follow where the data actually clumps.

  - `"fixed"` — cut points you supply yourself in `breaks`.

- breaks:

  Number of bins, or for `method = "fixed"` the vector of cut points.
  Default `3`.

- labels:

  Optional character vector of bin labels.

- include_lowest:

  Include the lowest value in the first bin. Default `TRUE`.

- right:

  Are intervals closed on the right? Default `FALSE`, i.e. `[a, b)`,
  matching the convention used for rule mining.

- ordered:

  Return an ordered factor? Default `FALSE`.

- infinity:

  Extend the outer breaks to `-Inf` and `Inf`, so values outside the
  training range still fall in a bin. Default `FALSE`.

- ...:

  Passed to [`base::cut()`](https://rdrr.io/r/base/cut.html).

## Value

A factor of the same length as `x`, or for a `data.frame` a `data.frame`
with its numeric columns replaced by factors.

## See also

[`transactions()`](https://mohsaqr.github.io/dynarules/reference/transactions.md)

## Examples

``` r
discretize_items(c(1, 3, 5, 7, 9, 11), breaks = 3)
#> [1] [1,4.33)    [1,4.33)    [4.33,7.67) [4.33,7.67) [7.67,11]   [7.67,11]  
#> Levels: [1,4.33) [4.33,7.67) [7.67,11]
discretize_items(c(1, 3, 5, 7, 9, 11), method = "interval", breaks = 2)
#> [1] [1,6)  [1,6)  [1,6)  [6,11] [6,11] [6,11]
#> Levels: [1,6) [6,11]
discretize_items(c(1, 2, 3, 10, 11, 12), method = "cluster", breaks = 2)
#> [1] [1,6.5)  [1,6.5)  [1,6.5)  [6.5,12] [6.5,12] [6.5,12]
#> Levels: [1,6.5) [6.5,12]
```
