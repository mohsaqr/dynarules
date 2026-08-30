# Plot Mined Rules

Six standard views of a rule set. `"scatter"` and `"two-key"` show the
whole set at a glance; `"matrix"` and `"grouped"` show which items pair
with which; `"graph"` and `"paracoord"` show the item-level structure.

## Usage

``` r
# S3 method for class 'dynarules'
plot(
  x,
  type = c("scatter", "two-key", "matrix", "grouped", "graph", "paracoord"),
  measure = "lift",
  top = NULL,
  level = c("item", "rule"),
  key = TRUE,
  ...
)
```

## Arguments

- x:

  A `dynarules` object.

- type:

  The view to draw: `"scatter"` (default) plots support against
  confidence coloured by `measure`; `"two-key"` colours the same scatter
  by rule order instead; `"matrix"` tiles antecedent against consequent;
  `"grouped"` collapses antecedents to their lead item; `"graph"` hands
  the rule network to
  [`cograph::splot()`](https://sonsoles.me/cograph/reference/splot.html);
  `"paracoord"` draws each rule as a path across item positions.

- measure:

  Measure to colour by; any name from
  [`list_measures()`](https://mohsaqr.github.io/dynarules/reference/list_measures.md).
  Default `"lift"`. Ignored by `"two-key"`.

- top:

  Integer or NULL. Plot only the top N rules by lift.

- level:

  For `type = "graph"`: `"item"` (default) draws the item-to-item
  network, `"rule"` draws one node per rule between the items it links –
  the standard association-rule graph.

- key:

  For `type = "graph", level = "rule"`: draw the size and colour key.
  Default `TRUE`.

- ...:

  For `type = "graph"`, passed on to
  [`cograph::splot()`](https://sonsoles.me/cograph/reference/splot.html)
  (layout, node and edge styling); ignored otherwise.

## Value

For `type = "graph"`, the plotted network object, invisibly – cograph
draws with base graphics. For every other type, the `ggplot` object,
invisibly.

## See also

[`measures()`](https://mohsaqr.github.io/dynarules/reference/measures.md),
[`rules()`](https://mohsaqr.github.io/dynarules/reference/rules.md),
[`as_network()`](https://mohsaqr.github.io/dynarules/reference/as_network.md)

## Examples

``` r
fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
                 min_support = 0.3, min_confidence = 0.3)
plot(fit)

plot(fit, type = "matrix", measure = "confidence")

if (requireNamespace("cograph", quietly = TRUE)) {
  plot(fit, type = "graph")
}
```
