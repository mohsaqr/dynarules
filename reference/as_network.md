# Convert Mined Rules to a Plottable Network

Builds an item-level directed network from a rule set: nodes are items,
and each rule contributes edges from every antecedent item to every
consequent item. Parallel edges (the same item pair reached by several
rules) are aggregated. The result mirrors the Nestimate / cograph
`netobject` layout and carries the `cograph_network` class, so it plots
directly with `cograph::splot(net)`.

## Usage

``` r
as_network(
  x,
  weight = "lift",
  aggregate = c("max", "mean", "sum"),
  top = NULL,
  directed = NULL,
  level = c("item", "rule"),
  size_by = "support",
  palette = "sequential",
  layout = "spring",
  label_rules = FALSE,
  node_size_range = c(4, 15),
  edge_width = 0.5,
  edge_alpha = 1
)
```

## Arguments

- x:

  A `dynarules` object.

- weight:

  Character. Which rule metric becomes the edge weight: any measure from
  [`list_measures()`](https://mohsaqr.github.io/dynarules/reference/list_measures.md),
  e.g. `"lift"` (default), `"confidence"`, `"support"`, `"kappa"`.

- aggregate:

  Character. How parallel edges combine: `"max"` (default), `"mean"`, or
  `"sum"`.

- top:

  Integer or NULL. Use only the top N rules by lift.

- directed:

  Logical or `NULL`. `NULL` (default) decides from the data: sequential
  rules are always directed, and co-occurrence rules are directed only
  when the chosen `weight` is asymmetric. Confidence, conviction and
  Laplace accuracy are asymmetric; lift, support, kappa, jaccard,
  cosine, phi and leverage are symmetric, so a lift-weighted
  co-occurrence network is undirected. Pass `TRUE`/`FALSE` to override.

- level:

  `"item"` (default) collapses rules into item-to-item edges: compact,
  and what centrality or community analysis wants. `"rule"` gives one
  node per rule, with antecedent items pointing into it and consequent
  items out of it – the standard association-rule graph. It keeps the
  conjunction that `"item"` loses: under `"item"`, `{a,b} => c` is
  indistinguishable from the two rules `a => c` and `b => c`.

- size_by:

  For `level = "rule"`, the measure driving rule-node size. Default
  `"support"`.

- palette:

  For `level = "rule"`, the node colour ramp: `"sequential"` (default),
  `"diverging"` (centred on independence when the weight is lift-like),
  `"greys"`, or a vector of colours.

- layout:

  For `level = "rule"`, the layout. `"spring"` (default) or `"gephi_fr"`
  are the force layouts that suit this graph shape. `"ring"` is also
  available: it places items on an outer circle with each rule at the
  centroid of the items it links.

- label_rules:

  For `level = "rule"`, what to write on the rule nodes. `FALSE`
  (default) leaves them bare, the association-rule convention: the
  node's meaning is its size, colour and position. `"id"` (or `TRUE`)
  numbers them `R1`, `R2`, ... so they can be looked up against
  [`rules()`](https://mohsaqr.github.io/dynarules/reference/rules.md).
  `"weight"` or `"size"` print the value driving that channel, `"both"`
  prints both, and `"rule"` prints the rule itself. A character vector,
  one per rule, sets the labels directly.

- node_size_range:

  For `level = "rule"`, the smallest and largest rule-node size. Default
  `c(4, 15)`.

- edge_width:

  For `level = "rule"`, edge thickness. A single value draws every edge
  the same width. Default `0.5`, i.e. thin.

- edge_alpha:

  For `level = "rule"`, edge opacity. Default `1`; cograph's own default
  of `0.8` leaves edges looking hazy.

## Value

An object of class `c("dynarules_net", "cograph_network")` with
`$weights` (item x item matrix), `$nodes`, `$edges` (integer from/to +
weight), `$directed = TRUE`, `$method`, `$n`.

## Examples

``` r
trans <- list(c("plan", "discuss", "reflect"),
              c("plan", "discuss", "execute"),
              c("plan", "reflect"),
              c("discuss", "reflect"))
fit <- dynarules(trans, min_support = 0.25, min_lift = 0)
net <- as_network(fit)
net$weights
#>           discuss execute      plan   reflect
#> discuss 0.0000000       2 1.3333333 0.8888889
#> execute 2.0000000       0 2.0000000 0.0000000
#> plan    1.3333333       2 0.0000000 0.8888889
#> reflect 0.8888889       0 0.8888889 0.0000000
```
