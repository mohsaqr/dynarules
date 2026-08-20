# ---- Transaction construction: the event-log grammar ----

#' Construct Transactions from Event Data
#'
#' @description
#' Builds the transaction set that rule mining operates on. The unit of
#' analysis (what counts as one transaction) is an explicit modeling
#' decision expressed through the `unit` argument, not an assumption about
#' the input format: a transaction can be an actor's session, an actor's
#' whole event stream, or a window of consecutive events.
#'
#' Each transaction is stored in two forms: the ordered action sequence
#' (used by sequential rule mining, where order matters) and the item set
#' (used by co-occurrence rule mining, where it does not).
#'
#' @param data Input data. One of:
#'   \describe{
#'     \item{long event log}{A data.frame with one row per event; requires
#'       `action`, optionally `actor`, `time`, `session`.}
#'     \item{wide data.frame}{One row per transaction, columns are
#'       consecutive actions (V1, V2, ...); leave `action` unset.}
#'     \item{list}{Each element an ordered character vector of actions
#'       (one transaction).}
#'     \item{binary matrix}{Rows are transactions, columns are items.
#'       Set form only: sequential mining is unavailable for this input.}
#'   }
#' @param actor Character or NULL. Column name(s) identifying who produced
#'   the event (long input only). Multiple columns are combined.
#' @param action Character or NULL. Column name of the action/state/code
#'   (long input only). Supplying `action` selects the long event-log path.
#' @param time Character or NULL. Column name of timestamps used to order
#'   events within each actor stream. If NULL, input row order is kept.
#' @param session Character or NULL. Column name(s) identifying the session
#'   an event belongs to (long input only).
#' @param weights Optional numeric vector of transaction weights, one per
#'   transaction, for weighted support. `NULL` (default) weights every
#'   transaction equally.
#' @param unit Character. What one transaction is: `"session"` (actor x
#'   session; the default), `"actor"` (an actor's full stream), or
#'   `"window"` (consecutive-event windows within each actor stream).
#' @param window Integer. Window width in events (`unit = "window"` only).
#' @param step Integer or NULL. Window step; NULL means tumbling windows
#'   (`step = window`).
#'
#' @return An object of class `"dyna_transactions"`:
#' \describe{
#'   \item{sequences}{List of ordered character vectors (NULL for binary
#'     matrix input).}
#'   \item{matrix}{Logical transaction x item set matrix.}
#'   \item{items}{Character vector of all items, sorted.}
#'   \item{ids}{Tidy data.frame with one row per transaction (actor,
#'     session, window index where applicable).}
#'   \item{n_transactions, unit, source}{Metadata.}
#' }
#'
#' @examples
#' log <- data.frame(
#'   student = rep(c("s1", "s2"), each = 4),
#'   code = c("plan", "discuss", "execute", "reflect",
#'            "plan", "research", "analyze", "reflect"),
#'   stringsAsFactors = FALSE
#' )
#' tr <- transactions(log, actor = "student", action = "code")
#' tr
#'
#' @export
transactions <- function(data,
                         actor = NULL,
                         action = NULL,
                         time = NULL,
                         session = NULL,
                         unit = c("session", "actor", "window"),
                         window = NULL,
                         step = NULL,
                         weights = NULL) {
  unit <- match.arg(unit)
  tr <- .tr_dispatch(data, actor = actor, action = action, time = time,
                     session = session, unit = unit, window = window,
                     step = step)
  if (is.null(weights)) return(tr)
  stopifnot(is.numeric(weights), length(weights) == tr$n_transactions,
            all(weights >= 0), all(is.finite(weights)))
  if (sum(weights) <= 0) {
    stop("`weights` must not sum to zero.", call. = FALSE)
  }
  tr$weights <- as.numeric(weights)
  tr
}


# The input-shape dispatch: matrix, list of sequences, wide data.frame, or
# the event-log grammar.
#' @noRd
.tr_dispatch <- function(data, actor, action, time, session, unit, window,
                         step) {

  if (is.matrix(data)) {
    return(.tr_from_matrix(data))
  }
  if (is.list(data) && !is.data.frame(data)) {
    stopifnot(all(vapply(data, is.character, logical(1))))
    return(.tr_from_sequences(unname(data), ids = NULL, unit = "given",
                              source = "list"))
  }
  if (!is.data.frame(data)) {
    stop("data must be a data.frame, list, or matrix.", call. = FALSE)
  }
  if (is.null(action)) {
    return(.tr_from_wide(data))
  }
  .tr_from_eventlog(data, actor = actor, action = action, time = time,
                    session = session, unit = unit, window = window,
                    step = step)
}


#' @noRd
.tr_from_eventlog <- function(df, actor, action, time, session, unit,
                              window, step) {
  stopifnot(is.character(action), length(action) == 1L,
            action %in% names(df))
  if (!is.null(actor)) {
    stopifnot(is.character(actor), all(actor %in% names(df)))
  }
  if (!is.null(session)) {
    stopifnot(is.character(session), all(session %in% names(df)))
  }
  if (!is.null(time)) {
    stopifnot(is.character(time), length(time) == 1L, time %in% names(df))
  }
  if (unit == "session" && is.null(session) && is.null(actor)) {
    stop("unit = \"session\" needs `session` and/or `actor` columns.",
         call. = FALSE)
  }
  if (unit == "window") {
    stopifnot(is.numeric(window), length(window) == 1L, window >= 2)
    window <- as.integer(window)
    step <- if (is.null(step)) window else as.integer(step)
    stopifnot(step >= 1L)
  }

  actor_key <- if (is.null(actor)) rep("all", nrow(df)) else {
    do.call(paste, c(df[actor], sep = " | "))
  }
  session_key <- if (is.null(session)) rep(NA_character_, nrow(df)) else {
    do.call(paste, c(df[session], sep = " | "))
  }

  # Order events within each stream: by time when given, input order as
  # tie-break; otherwise input order.
  ord <- if (is.null(time)) {
    order(actor_key, seq_len(nrow(df)))
  } else {
    order(actor_key, df[[time]], seq_len(nrow(df)))
  }
  act <- as.character(df[[action]])[ord]
  actor_key <- actor_key[ord]
  session_key <- session_key[ord]

  keep <- !is.na(act) & act != ""
  act <- act[keep]
  actor_key <- actor_key[keep]
  session_key <- session_key[keep]

  group_key <- switch(unit,
    session = if (is.null(session)) actor_key else {
      paste(actor_key, session_key, sep = " | ")
    },
    actor = actor_key,
    window = actor_key
  )

  seqs <- split(act, factor(group_key, levels = unique(group_key)))
  ids <- data.frame(
    actor = vapply(split(actor_key,
                         factor(group_key, levels = unique(group_key))),
                   `[`, character(1), 1L),
    session = vapply(split(session_key,
                           factor(group_key, levels = unique(group_key))),
                     `[`, character(1), 1L),
    stringsAsFactors = FALSE, row.names = NULL
  )

  if (unit == "window") {
    win <- .tr_windows(seqs, ids, window, step)
    seqs <- win$seqs
    ids <- win$ids
  }

  .tr_from_sequences(unname(seqs), ids = ids, unit = unit,
                     source = "eventlog")
}


# Cut each actor stream into windows of `window` consecutive events moved
# by `step` (tumbling when step == window). Trailing windows shorter than
# `window` are kept when they hold at least two events.
#' @noRd
.tr_windows <- function(seqs, ids, window, step) {
  per_stream <- lapply(seq_along(seqs), function(i) {
    s <- seqs[[i]]
    starts <- seq(1L, max(1L, length(s)), by = step)
    starts <- starts[starts <= length(s)]
    pieces <- lapply(starts, function(st) {
      s[st:min(st + window - 1L, length(s))]
    })
    keep <- lengths(pieces) >= 2L
    pieces <- pieces[keep]
    if (length(pieces) == 0L) return(NULL)
    list(
      seqs = pieces,
      ids = data.frame(actor = ids$actor[i], session = ids$session[i],
                       window = seq_along(pieces),
                       stringsAsFactors = FALSE)
    )
  })
  per_stream <- Filter(Negate(is.null), per_stream)
  if (length(per_stream) == 0L) {
    stop("No windows with at least 2 events; lower `window` or check data.",
         call. = FALSE)
  }
  list(
    seqs = do.call(c, lapply(per_stream, `[[`, "seqs")),
    ids = do.call(rbind, lapply(per_stream, `[[`, "ids"))
  )
}


#' @noRd
.tr_from_wide <- function(df) {
  seqs <- lapply(seq_len(nrow(df)), function(i) {
    vals <- as.character(unlist(df[i, ], use.names = FALSE))
    vals[!is.na(vals) & vals != ""]
  })
  keep <- lengths(seqs) > 0L
  .tr_from_sequences(seqs[keep], ids = NULL, unit = "row", source = "wide")
}


#' @noRd
.tr_from_matrix <- function(mat) {
  items <- colnames(mat)
  if (is.null(items)) items <- paste0("I", seq_len(ncol(mat)))
  colnames(mat) <- items
  ord <- order(items)
  set_mat <- (mat > 0)[, ord, drop = FALSE]
  structure(list(
    sequences = NULL,
    matrix = set_mat,
    items = items[ord],
    ids = NULL,
    n_transactions = nrow(set_mat),
    unit = "row",
    source = "matrix"
  ), class = "dyna_transactions")
}


#' @noRd
.tr_from_sequences <- function(seqs, ids, unit, source) {
  if (length(seqs) == 0L) {
    stop("No transactions found in `data`.", call. = FALSE)
  }
  sets <- lapply(seqs, unique)
  items <- sort(unique(unlist(sets, use.names = FALSE)))

  row_idx <- rep(seq_along(sets), lengths(sets))
  col_idx <- match(unlist(sets, use.names = FALSE), items)
  set_mat <- matrix(FALSE, length(sets), length(items),
                    dimnames = list(NULL, items))
  set_mat[cbind(row_idx, col_idx)] <- TRUE

  structure(list(
    sequences = seqs,
    matrix = set_mat,
    items = items,
    ids = ids,
    n_transactions = length(seqs),
    unit = unit,
    source = source
  ), class = "dyna_transactions")
}


#' Print Method for dyna_transactions
#'
#' @param x A `dyna_transactions` object.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.dyna_transactions <- function(x, ...) {
  cat(sprintf("<dyna_transactions>  %d transactions | %d items | unit: %s\n",
              x$n_transactions, length(x$items), x$unit))
  if (!is.null(x$sequences)) {
    cat(sprintf("  mean events per transaction: %.1f (ordered sequences kept)\n",
                mean(lengths(x$sequences))))
  } else {
    cat("  set form only (binary matrix input; sequential mining unavailable)\n")
  }
  invisible(x)
}


#' Summary Method for dyna_transactions
#'
#' @param object A `dyna_transactions` object.
#' @param ... Ignored.
#' @return A tidy data.frame with one row per item: its support (fraction
#'   of transactions containing it) and count.
#' @export
summary.dyna_transactions <- function(object, ...) {
  counts <- colSums(object$matrix)
  data.frame(
    item = object$items,
    count = as.integer(counts),
    support = as.numeric(counts) / object$n_transactions,
    stringsAsFactors = FALSE, row.names = NULL
  )
}
