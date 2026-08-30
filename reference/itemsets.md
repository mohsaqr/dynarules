# Frequent Itemsets and Their Closed, Maximal and Generator Subsets

Returns the frequent itemsets (co-occurrence) or frequent sequential
patterns behind a mined rule set, optionally restricted to one of the
standard condensed representations.

## Usage

``` r
itemsets(
  x,
  target = c("frequent", "closed", "maximal", "generator"),
  min_size = NULL,
  max_size = NULL,
  top = NULL
)
```

## Arguments

- x:

  A `dynarules` object.

- target:

  One of `"frequent"`, `"closed"`, `"maximal"`, `"generator"`.

- min_size, max_size:

  Optional integer bounds on the number of items in a pattern.

- top:

  Optional integer; keep only the `top` patterns by support.

## Value

A tidy `data.frame` with one row per pattern: `pattern`, `size`,
`support`, `count`.

## Details

- `"frequent"` — every pattern meeting `min_support`.

- `"closed"` — no proper superpattern has the same support. The
  loss-less summary: supports of all frequent patterns are recoverable.

- `"maximal"` — no proper superpattern is frequent at all. The smallest
  summary, but supports of sub-patterns are lost.

- `"generator"` — no proper subpattern has the same support; the minimal
  patterns of each equivalence class.

## See also

[`rules()`](https://mohsaqr.github.io/dynarules/reference/rules.md),
[`measures()`](https://mohsaqr.github.io/dynarules/reference/measures.md)

## Examples

``` r
fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
                 min_support = 0.3, min_confidence = 0.3)
itemsets(fit)
#>   pattern size   support count
#> 1       a    1 1.0000000     3
#> 2       b    1 0.6666667     2
#> 3       c    1 0.6666667     2
#> 4    a, b    2 0.6666667     2
#> 5    a, c    2 0.6666667     2
#> 6    b, c    2 0.3333333     1
#> 7 a, b, c    3 0.3333333     1
itemsets(fit, target = "closed")
#>   pattern size   support count
#> 1       a    1 1.0000000     3
#> 2    a, b    2 0.6666667     2
#> 3    a, c    2 0.6666667     2
#> 4 a, b, c    3 0.3333333     1
itemsets(fit, target = "maximal")
#>   pattern size   support count
#> 1 a, b, c    3 0.3333333     1
```
