# Construct Transactions from Event Data

Builds the transaction set that rule mining operates on. The unit of
analysis (what counts as one transaction) is an explicit modeling
decision expressed through the `unit` argument, not an assumption about
the input format: a transaction can be an actor's session, an actor's
whole event stream, or a window of consecutive events.

Each transaction is stored in two forms: the ordered action sequence
(used by sequential rule mining, where order matters) and the item set
(used by co-occurrence rule mining, where it does not).

## Usage

``` r
transactions(
  data,
  actor = NULL,
  action = NULL,
  time = NULL,
  session = NULL,
  unit = c("session", "actor", "window"),
  window = NULL,
  step = NULL,
  weights = NULL
)
```

## Arguments

- data:

  Input data. One of:

  long event log

  :   A data.frame with one row per event; requires `action`, optionally
      `actor`, `time`, `session`.

  wide data.frame

  :   One row per transaction, columns are consecutive actions (V1, V2,
      ...); leave `action` unset.

  list

  :   Each element an ordered character vector of actions (one
      transaction).

  binary matrix

  :   Rows are transactions, columns are items. Set form only:
      sequential mining is unavailable for this input.

- actor:

  Character or NULL. Column name(s) identifying who produced the event
  (long input only). Multiple columns are combined.

- action:

  Character or NULL. Column name of the action/state/code (long input
  only). Supplying `action` selects the long event-log path.

- time:

  Character or NULL. Column name of timestamps used to order events
  within each actor stream. If NULL, input row order is kept.

- session:

  Character or NULL. Column name(s) identifying the session an event
  belongs to (long input only).

- unit:

  Character. What one transaction is: `"session"` (actor x session; the
  default), `"actor"` (an actor's full stream), or `"window"`
  (consecutive-event windows within each actor stream).

- window:

  Integer. Window width in events (`unit = "window"` only).

- step:

  Integer or NULL. Window step; NULL means tumbling windows
  (`step = window`).

- weights:

  Optional numeric vector of transaction weights, one per transaction,
  for weighted support. `NULL` (default) weights every transaction
  equally.

## Value

An object of class `"dyna_transactions"`:

- sequences:

  List of ordered character vectors (NULL for binary matrix input).

- matrix:

  Logical transaction x item set matrix.

- items:

  Character vector of all items, sorted.

- ids:

  Tidy data.frame with one row per transaction (actor, session, window
  index where applicable).

- n_transactions, unit, source:

  Metadata.

## Examples

``` r
log <- data.frame(
  student = rep(c("s1", "s2"), each = 4),
  code = c("plan", "discuss", "execute", "reflect",
           "plan", "research", "analyze", "reflect"),
  stringsAsFactors = FALSE
)
tr <- transactions(log, actor = "student", action = "code")
tr
#> <dyna_transactions>  2 transactions | 6 items | unit: session
#>   mean events per transaction: 4.0 (ordered sequences kept)
```
