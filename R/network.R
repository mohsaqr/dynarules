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
#' @param weight Character. Which rule metric becomes the edge weight: any
#'   measure from [list_measures()], e.g. `"lift"` (default),
#'   `"confidence"`, `"support"`, `"kappa"`.
#' @param aggregate Character. How parallel edges combine: `"max"`
#'   (default), `"mean"`, or `"sum"`.
#' @param level `"item"` (default) collapses rules into item-to-item
#'   edges: compact, and what centrality or community analysis wants.
#'   `"rule"` gives one node per rule, with antecedent items pointing into
#'   it and consequent items out of it -- the standard association-rule
#'   graph. It keeps the conjunction that `"item"` loses: under `"item"`,
#'   `{a,b} => c` is indistinguishable from the two rules `a => c` and
#'   `b => c`.
#' @param size_by For `level = "rule"`, the measure driving rule-node
#'   size. Default `"support"`.
#' @param palette For `level = "rule"`, the node colour ramp:
#'   `"sequential"` (default), `"diverging"` (centred on independence when
#'   the weight is lift-like), `"greys"`, or a vector of colours.
#' @param layout For `level = "rule"`, the layout. `"spring"` (default)
#'   or `"gephi_fr"` are the force layouts that suit this graph shape.
#'   `"ring"` is also available: it places items on an outer circle with
#'   each rule at the centroid of the items it links.
#' @param node_size_range For `level = "rule"`, the smallest and largest
#'   rule-node size. Default `c(4, 15)`.
#' @param edge_width For `level = "rule"`, edge thickness. A single value
#'   draws every edge the same width. Default `0.5`, i.e. thin.
#' @param edge_alpha For `level = "rule"`, edge opacity. Default `1`;
#'   cograph's own default of `0.8` leaves edges looking hazy.
#' @param label_rules For `level = "rule"`, what to write on the rule
#'   nodes. `FALSE` (default) leaves them bare, the association-rule
#'   convention: the node's meaning is its size, colour and position.
#'   `"id"` (or `TRUE`) numbers them `R1`, `R2`, ... so they can be looked
#'   up against [rules()]. `"weight"` or `"size"` print the value driving
#'   that channel, `"both"` prints both, and `"rule"` prints the rule
#'   itself. A character vector, one per rule, sets the labels directly.
#' @param directed Logical or `NULL`. `NULL` (default) decides from the
#'   data: sequential rules are always directed, and co-occurrence rules
#'   are directed only when the chosen `weight` is asymmetric. Confidence,
#'   conviction and Laplace accuracy are asymmetric; lift, support, kappa,
#'   jaccard, cosine, phi and leverage are symmetric, so a lift-weighted
#'   co-occurrence network is undirected. Pass `TRUE`/`FALSE` to override.
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
                       edge_alpha = 1) {
  stopifnot(inherits(x, "dynarules"), is.character(weight),
            length(weight) == 1L)
  if (!weight %in% names(.DR_MEASURES)) {
    stop("Unknown weight measure: ", weight, ". See list_measures().",
         call. = FALSE)
  }
  level <- match.arg(level)
  if (level == "rule") {
    return(.dr_rule_network(x, weight = weight, top = top, size_by = size_by,
                            palette = palette, layout = layout,
                            label_rules = label_rules,
                            node_size_range = node_size_range,
                            edge_width = edge_width,
                            edge_alpha = edge_alpha))
  }
  aggregate <- match.arg(aggregate)
  agg_fn <- switch(aggregate, max = max, mean = mean, sum = sum)

  r <- .dr_plot_data(x, weight, top)
  r[[weight]] <- r$w
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

  # Whether the network is directed is a property of the weight, not an
  # assumption. Sequential rules are directed by construction. For
  # co-occurrence it depends on the measure: confidence and conviction are
  # asymmetric, but lift, support, kappa, jaccard and friends are symmetric,
  # and drawing those as two arrows would claim a direction the numbers do
  # not carry. Detecting it from the matrix keeps this correct for all 50
  # measures without a hand-maintained classification.
  if (is.null(directed)) {
    directed <- x$type == "sequential" ||
      !isTRUE(all.equal(weights, t(weights), check.attributes = FALSE))
  }
  stopifnot(is.logical(directed), length(directed) == 1L)

  nodes <- data.frame(id = seq_along(labels), label = labels, name = labels,
                      x = NA_real_, y = NA_real_, stringsAsFactors = FALSE)
  edge_idx <- which(weights != 0, arr.ind = TRUE)
  # An undirected network must carry one edge per pair, not both
  # orientations of a symmetric weight -- cograph rejects the duplicate,
  # and rightly so.
  if (!directed) {
    edge_idx <- edge_idx[edge_idx[, 1L] < edge_idx[, 2L], , drop = FALSE]
  }
  edges <- data.frame(from = as.integer(edge_idx[, 1L]),
                      to = as.integer(edge_idx[, 2L]),
                      weight = weights[edge_idx], row.names = NULL)

  structure(list(
    nodes = nodes, edges = edges, directed = directed, weights = weights,
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
