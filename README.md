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

Part of the Dynalytics R family alongside
[Nestimate](https://github.com/mohsaqr/Nestimate) (network estimation)
and [psychnets](https://github.com/mohsaqr/psychnets) (psychometric
networks).
