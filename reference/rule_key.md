# Draw the Size and Colour Key for a Rule Network

cograph's legend covers discrete groups, edge colours and a node-size
scale, but not the two continuous encodings an association-rule graph
uses. This draws that key onto the current plot after
[`cograph::splot()`](https://sonsoles.me/cograph/reference/splot.html)
has run.

## Usage

``` r
rule_key(
  net,
  position = c("bottomleft", "bottomright", "topleft", "topright"),
  cex = 0.75
)
```

## Arguments

- net:

  A rule-level network from
  [`as_network()`](https://mohsaqr.github.io/dynarules/reference/as_network.md)
  with `level = "rule"`.

- position:

  Corner for the key: `"bottomleft"` (default), `"bottomright"`,
  `"topleft"`, `"topright"`.

- cex:

  Text size. Default `0.75`.

## Value

`net`, invisibly.

## See also

[`as_network()`](https://mohsaqr.github.io/dynarules/reference/as_network.md)

## Examples

``` r
fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
                 min_support = 0.3, min_confidence = 0.3)
net <- as_network(fit, level = "rule")
if (requireNamespace("cograph", quietly = TRUE)) {
  cograph::splot(net)
  rule_key(net)
}
```
