# dynarules

Association and sequential rule mining for temporal event data, in
clean-room base R.

Event data — learning traces, coded interactions, clickstreams — arrives
as a log of who did what, when. `dynarules` mines two kinds of rules from
it:

- **Co-occurrence rules** (`plan, discuss => reflect`): which actions
  appear together in a transaction, order ignored. Level-wise Apriori
  with full candidate pruning.
- **Sequential rules** (`plan -> discuss => reflect`): which ordered
  patterns predict what comes later. Generalized sequential pattern
  mining; support is non-contiguous subsequence containment.

## The transaction grammar

What counts as one transaction is a modeling decision, not a file format:

```r
library(dynarules)

tr <- transactions(log, actor = "student", action = "code",
                   time = "timestamp", session = "lesson")
# unit = "session" (default) | "actor" | "window" (+ window =, step =)

fit <- dynarules(tr, type = "sequential", min_support = 0.2)
fit
rules(fit, min_lift = 1.5, items = "reflect", side = "consequent")
```

Wide data.frames, lists of vectors, and binary matrices are also
accepted; the event-log grammar can be passed straight to `dynarules()`.

## Preparing transactions

```r
discretize(scores, method = "cluster", breaks = 3)   # numeric -> items
discretize(df, breaks = 3)                           # every numeric column

read_transactions("baskets.csv")                     # one line per basket
read_transactions("log.csv", format = "single")      # one line per item

item_frequency(tr)                    # tidy: item, count, support
cross_table(tr, measure = "lift")     # tidy pairwise co-occurrence
affinity(tr)                          # tidy pairwise Jaccard
support_of(tr, list(c("read", "quiz")))   # support without mining

sample_transactions(tr, size = 100)
random_transactions(500, 10, density = 0.3)   # synthetic null data
add_complement(tr, items = "submit")          # mine about absence too
aggregate_items(tr, c(read = "study", video = "study"))  # roll up a hierarchy
```

Weighted support, where transactions do not all count equally:

```r
tr <- transactions(log, actor = "student", action = "code", weights = w)
dynarules(tr, min_support = 0.1)   # support = share of weight, not of rows
```

## 50 interest measures

Support, confidence and lift are three of the fifty measures the
literature defines. All of them are one verb away, and each is verified
to match `arules::interestMeasure()` exactly:

```r
list_measures()                                   # the catalogue
measures(fit)                                     # the four headline measures
measures(fit, measure = c("kappa", "phi", "jaccard", "conviction"))
measures(fit, measure = "all", counts = TRUE)     # everything + the 2x2 table
```

## Which rules are worth keeping

Predicates return one logical per rule, and `rules()` takes them as
arguments — so filtering never means subsetting by hand:

```r
rules(fit, significant = TRUE, adjust = "BH")   # Fisher's exact vs independence
rules(fit, redundant = FALSE)                   # drop rules a shorter one beats
rules(fit, maximal = TRUE, top = 20, by = "lift")

is_significant(fit); is_redundant(fit); is_maximal(fit)
```

## Frequent itemsets and their condensed forms

```r
itemsets(fit)                        # every frequent pattern
itemsets(fit, target = "closed")     # loss-less summary
itemsets(fit, target = "maximal")    # smallest summary
itemsets(fit, target = "generator")  # minimal patterns per class
```

## Constrained mining

```r
dynarules(tr, min_length = 3, max_length = 5,
          appearance = list(rhs = "reflect", none = c("login", "logout")))
```

## Six views of a rule set

```r
plot(fit)                                  # scatter (default)
plot(fit, type = "two-key")                # coloured by rule order
plot(fit, type = "matrix",  measure = "confidence")
plot(fit, type = "grouped")
plot(fit, type = "graph")                  # item network, no layout package
plot(fit, type = "paracoord")
```

Any of the fifty measures can drive the colour: `plot(fit, measure = "kappa")`.

## Rules are estimates — treat them like it

```r
bootstrap_rules(fit, iter = 500)   # recovery + percentile CIs per rule
permute_rules(fit, iter = 1000)    # significance against an explicit null
```

The sequential null shuffles order *within* each transaction: it keeps
exactly which actions co-occur and destroys only their order, so a
surviving sequential rule is informative beyond co-occurrence.

## Rules as a network

```r
net <- as_network(fit, weight = "lift")
cograph::splot(net)   # netobject-compatible, directed items network
```

## Install

```r
# development version
remotes::install_github("mohsaqr/dynarules")
```

## Relationship to arules

`dynarules` is a clean-room base-R implementation, not a wrapper. Its
measures, condensed itemset targets, redundancy and significance
predicates are pinned to `arules` numerically by an equivalence suite,
while the transaction grammar, sequential mining and inference verbs have
no `arules` counterpart. Two definitional differences are deliberate:
`dynarules` generates multi-item consequents (`arules::apriori` emits
single-item ones only), and it never produces empty-antecedent rules.

Part of the Dynalytics R family alongside
[Nestimate](https://github.com/mohsaqr/Nestimate) (network estimation)
and [psychnets](https://github.com/mohsaqr/psychnets) (psychometric
networks).
