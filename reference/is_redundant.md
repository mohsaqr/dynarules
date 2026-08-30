# Which Rules Are Redundant?

A rule is redundant when a more general rule – same consequent, an
antecedent contained in this one's (a subset for co-occurrence rules, an
ordered subsequence for sequential ones) – reaches at least the same
confidence. The extra items in the antecedent buy nothing.

## Usage

``` r
is_redundant(x)
```

## Arguments

- x:

  A `dynarules` object.

## Value

A logical vector with one entry per mined rule.

## See also

[`rules()`](https://mohsaqr.github.io/dynarules/reference/rules.md),
[`is_significant()`](https://mohsaqr.github.io/dynarules/reference/is_significant.md),
[`is_maximal()`](https://mohsaqr.github.io/dynarules/reference/is_maximal.md)

## Examples

``` r
fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
                 min_support = 0.3, min_confidence = 0.3)
is_redundant(fit)
#> [1] FALSE FALSE  TRUE FALSE FALSE FALSE
rules(fit, redundant = FALSE)
#>   antecedent consequent   support confidence lift conviction support_antecedent
#> 1          b          a 0.6666667  1.0000000    1        Inf          0.6666667
#> 2          c          a 0.6666667  1.0000000    1        Inf          0.6666667
#> 3          a          b 0.6666667  0.6666667    1          1          1.0000000
#> 4          a          c 0.6666667  0.6666667    1          1          1.0000000
#> 5          a       b, c 0.3333333  0.3333333    1          1          1.0000000
#>   support_consequent count n_transactions
#> 1          1.0000000     2              3
#> 2          1.0000000     2              3
#> 3          0.6666667     2              3
#> 4          0.6666667     2              3
#> 5          0.3333333     1              3
```
