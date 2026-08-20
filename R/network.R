# ---- Rules -> network object ----

#' Convert Mined Rules to a Plottable Network
#'
#' @description
#' Builds an item-level directed network from a rule set: nodes are items,
#' and each rule contributes edges from every antecedent item to every
#' consequent item. Parallel edges (the same item pair reached by several
#' rules) are aggregated. The result mirrors the Nestimate / cograph
#' `netobject` layout and carries the `cograph_network` class, so it plots
#' directly with `cograph::splot(net)`.
#'
#' @param x A `dynarules` object.
#' @param weight Character. Which rule metric becomes the edge weight:
#'   `"lift"` (default), `"confidence"`, or `"support"`.
#' @param aggregate Character. How parallel edges combine: `"max"`
#'   (default), `"mean"`, or `"sum"`.
#' @param top Integer or NULL. Use only the top N rules by lift.
#'
#' @return An object of class `c("dynarules_net", "cograph_network")` with
#'   `$weights` (item x item matrix), `$nodes`, `$edges` (integer
#'   from/to + weight), `$directed = TRUE`, `$method`, `$n`.
#'
#' @examples
#' trans <- list(c("plan", "discuss", "reflect"),
#'               c("plan", "discuss", "execute"),
#'               c("plan", "reflect"),
#'               c("discuss", "reflect"))
#' fit <- dynarules(trans, min_support = 0.25, min_lift = 0)
#' net <- as_network(fit)
#' net$weights
#'
#' @export
as_network <- function(x,
                       weight = c("lift", "confidence", "support"),
                       aggregate = c("max", "mean", "sum"),
                       top = NULL) {
  stopifnot(inherits(x, "dynarules"))
  weight <- match.arg(weight)
  aggregate <- match.arg(aggregate)
  agg_fn <- switch(aggregate, max = max, mean = mean, sum = sum)

  r <- rules(x, top = top)
  sep <- if (x$type == "sequential") " -> " else ", "

  pair_rows <- lapply(seq_len(nrow(r)), function(i) {
    ante <- strsplit(r$antecedent[i], sep, fixed = TRUE)[[1L]]
    cons <- strsplit(r$consequent[i], sep, fixed = TRUE)[[1L]]
    expand.grid(from = unique(ante), to = unique(cons),
                stringsAsFactors = FALSE) |>
      within(w <- r[[weight]][i])
  })
  pairs <- do.call(rbind, pair_rows)

  labels <- x$items
  weights <- matrix(0, length(labels), length(labels),
                    dimnames = list(labels, labels))
  if (!is.null(pairs) && nrow(pairs) > 0L) {
    agg <- stats::aggregate(w ~ from + to, data = pairs, FUN = agg_fn)
    weights[cbind(match(agg$from, labels), match(agg$to, labels))] <- agg$w
  }
  diag(weights) <- 0

  nodes <- data.frame(id = seq_along(labels), label = labels, name = labels,
                      x = NA_real_, y = NA_real_, stringsAsFactors = FALSE)
  edge_idx <- which(weights != 0, arr.ind = TRUE)
  edges <- data.frame(from = as.integer(edge_idx[, 1L]),
                      to = as.integer(edge_idx[, 2L]),
                      weight = weights[edge_idx], row.names = NULL)

  structure(list(
    nodes = nodes, edges = edges, directed = TRUE, weights = weights,
    data = NULL, meta = list(source = "dynarules", weight = weight,
                             aggregate = aggregate, type = x$type),
    node_groups = NULL,
    method = paste0("rules_", x$type),
    n = x$n_transactions
  ), class = c("dynarules_net", "cograph_network"))
}


#' Print Method for dynarules_net
#'
#' @param x A `dynarules_net` object.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.dynarules_net <- function(x, ...) {
  cat(sprintf("<dynarules_net> %s network\n", x$method))
  cat(sprintf("  nodes: %d   edges: %d   (directed; weight = %s, %s)\n",
              nrow(x$nodes), nrow(x$edges),
              x$meta$weight, x$meta$aggregate))
  invisible(x)
}
