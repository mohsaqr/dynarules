# Which Rules Rest on a Maximal Itemset?

A rule is maximal when no other mined rule is built on a strictly larger
pattern containing this rule's items. Maximal rules are the most
specific ones the mining produced.

## Usage

``` r
is_maximal(x)
```

## Arguments

- x:

  A `dynarules` object.

## Value

A logical vector with one entry per mined rule.

## See also

[`itemsets()`](https://mohsaqr.github.io/dynarules/reference/itemsets.md),
[`rules()`](https://mohsaqr.github.io/dynarules/reference/rules.md)

## Examples

``` r
fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
                 min_support = 0.3, min_confidence = 0.3)
is_maximal(fit)
#> [1] FALSE FALSE  TRUE FALSE FALSE  TRUE
```
