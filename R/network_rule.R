# The rule-level network: one node per rule, sitting between the items it
# links. The item-level network in as_network(level = "item") collapses
# rules into item-to-item edges, which loses the conjunction -- {a,b} => c
# becomes indistinguishable from two separate rules a => c and b => c. The
# rule-level form keeps it: antecedent items point INTO a rule node, and
# the rule node points OUT to the consequent items.

# Ramps for the rule nodes. "sequential" is the association-rule
# convention (pale = low, saturated = high). "diverging" is the dynarules
# house ramp, centred on the independence point so a lift below 1 reads
# red and above 1 reads blue -- only meaningful for measures with a
# natural centre.
#' @noRd
.DR_RULE_PALETTES <- list(
  sequential = c("#FFF7BC", "#FEC44F", "#E8853D", "#D33F6A"),
  diverging  = c("#D33F6A", "#E8E8E8", "#4A6FE3"),
  greys      = c("#F0F0F0", "#636363")
)

#' @noRd
.dr_ramp <- function(values, palette = "sequential", centre = NULL) {
  cols <- .DR_RULE_PALETTES[[palette]]
  if (is.null(cols)) cols <- palette
  ramp <- grDevices::colorRampPalette(cols)(101)
  if (length(values) == 0L) return(character(0))
  rng <- range(values, na.rm = TRUE)
  pos <- if (!is.null(centre) && diff(rng) > 0) {
    # Anchor the ramp's midpoint on `centre` so the neutral colour lands
    # exactly at independence rather than at the middle of the data.
    half <- max(abs(rng - centre))
    if (half == 0) rep(0.5, length(values)) else
      pmin(pmax((values - centre) / (2 * half) + 0.5, 0), 1)
  } else if (diff(rng) > 0) {
    (values - rng[1L]) / diff(rng)
  } else {
    rep(0.5, length(values))
  }
  ramp[1L + round(100 * pos)]
}


# A deterministic layout built for this graph shape. Force layouts put
# high-degree nodes in the middle, and in a rule graph the ITEMS are the
# high-degree nodes -- so they collapse into an unreadable pile at the
# centre while the rules ring the outside, which is backwards. This puts
# items on an outer ring, spaced apart so their labels are legible, and
# places each rule at the centroid of the items it connects, pulled inward.
# Rules landing on top of each other are pushed apart along the radius.
#' @noRd
.dr_ring_layout <- function(n_item, n_rule, antes, conss, items) {
  ang <- seq(0, 2 * pi, length.out = n_item + 1L)[seq_len(n_item)]
  ix <- cos(ang)
  iy <- sin(ang)

  centre <- t(vapply(seq_len(n_rule), function(i) {
    idx <- match(c(antes[[i]], conss[[i]]), items)
    c(mean(ix[idx]), mean(iy[idx]))
  }, numeric(2)))
  # Pull rules inward off the item ring so labels are not overplotted.
  centre <- centre * 0.62

  # Separate coincident rule nodes: rules sharing the same item set land on
  # the same centroid, so fan them out on a small circle around it.
  key <- vapply(seq_len(n_rule), function(i) {
    paste(sort(unique(c(antes[[i]], conss[[i]]))), collapse = "\r")
  }, character(1))
  invisible(lapply(split(seq_len(n_rule), key), function(grp) {
    if (length(grp) < 2L) return(NULL)
    th <- seq(0, 2 * pi, length.out = length(grp) + 1L)[seq_along(grp)]
    centre[grp, 1L] <<- centre[grp, 1L] + 0.17 * cos(th)
    centre[grp, 2L] <<- centre[grp, 2L] + 0.17 * sin(th)
  }))

  data.frame(x = c(ix, centre[, 1L]), y = c(iy, centre[, 2L]))
}


#' @noRd
.dr_rule_network <- function(x, weight, top, size_by, palette, layout,
                             label_rules, node_size_range, edge_width,
                             edge_alpha) {
  r <- .dr_plot_data(x, weight, top)
  if (!size_by %in% names(r)) {
    m <- measures(x, measure = size_by)
    r[[size_by]] <- m[[size_by]][match(
      paste(r$antecedent, r$consequent, sep = "\r"),
      paste(m$antecedent, m$consequent, sep = "\r"))]
  }
  sep <- if (x$type == "sequential") " -> " else ", "
  antes <- strsplit(r$antecedent, sep, fixed = TRUE)
  conss <- strsplit(r$consequent, sep, fixed = TRUE)

  items <- sort(unique(unlist(c(antes, conss), use.names = FALSE)))
  n_item <- length(items)
  n_rule <- nrow(r)
  rule_ids <- n_item + seq_len(n_rule)

  # Rule nodes are anonymous by convention -- their meaning is size,
  # colour and position -- but that makes them impossible to look up in
  # rules(), so the label is an argument rather than a fixed choice.
  rule_labels <- .dr_rule_labels(label_rules, r, weight, size_by, n_rule)
  labels <- c(items, rule_labels)
  nodes <- data.frame(
    id = seq_len(n_item + n_rule),
    label = labels,
    name = c(items, paste0("rule", seq_len(n_rule))),
    kind = c(rep("item", n_item), rep("rule", n_rule)),
    x = NA_real_, y = NA_real_, stringsAsFactors = FALSE
  )

  # Antecedent items -> rule, rule -> consequent items.
  edge_rows <- lapply(seq_len(n_rule), function(i) {
    a <- match(antes[[i]], items)
    b <- match(conss[[i]], items)
    data.frame(from = c(a, rep(rule_ids[i], length(b))),
               to = c(rep(rule_ids[i], length(a)), b),
               weight = r[[weight]][i], stringsAsFactors = FALSE)
  })
  edges <- do.call(rbind, edge_rows)
  row.names(edges) <- NULL

  n_all <- n_item + n_rule
  weights <- matrix(0, n_all, n_all, dimnames = list(nodes$name, nodes$name))
  weights[cbind(edges$from, edges$to)] <- edges$weight

  # Items carry no marker: size 0 leaves the label alone on the canvas,
  # which is how association-rule graphs are conventionally drawn.
  node_size <- c(rep(0, n_item),
                 .dr_scale(r[[size_by]], node_size_range))
  centre <- if (weight %in% c("lift", "LIC", "boost")) 1 else NULL
  node_fill <- c(rep(NA_character_, n_item),
                 .dr_ramp(r[[weight]], palette, centre))

  coords <- .dr_ring_layout(n_item, n_rule, antes, conss, items)
  if (identical(layout, "ring")) {
    nodes$x <- coords$x
    nodes$y <- coords$y
  }
  layout_defaults <- if (identical(layout, "ring")) {
    list(layout = "custom", coords = as.matrix(coords))
  } else {
    list(layout = layout)
  }

  structure(list(
    nodes = nodes, edges = edges, directed = TRUE, weights = weights,
    data = NULL,
    meta = list(
      source = "dynarules", level = "rule", weight = weight,
      size_by = size_by, type = x$type,
      ranges = list(size = range(r[[size_by]]), colour = range(r[[weight]])),
      # The producer contract: cograph renders from this hint, and any
      # argument the caller passes to splot() still wins.
      splot = list(
        renderer = "network",
        defaults = c(layout_defaults, list(
          node_size = node_size,
          node_fill = node_fill,
          node_shape = "circle",
          labels = nodes$label,
          groups = nodes$kind,
          show_arrows = TRUE,
          edge_color = "#5B8FF9",
          edge_width = edge_width,
          edge_alpha = edge_alpha,
          arrow_size = 0.8,
          node_border_color = "grey35",
          label_size = 0.95,
          label_fontface = "bold",
          legend = FALSE
        ))
      )
    ),
    node_groups = nodes$kind,
    method = paste0("rules_", x$type, "_bipartite"),
    n = x$n_transactions
  ), class = c("dynarules_net", "cograph_network"))
}


#' @noRd
.dr_rule_labels <- function(label_rules, r, weight, size_by, n_rule) {
  if (is.character(label_rules) && length(label_rules) == n_rule) {
    return(label_rules)
  }
  if (isFALSE(label_rules)) return(rep("", n_rule))
  if (isTRUE(label_rules)) label_rules <- "id"
  stopifnot(is.character(label_rules), length(label_rules) == 1L)
  switch(label_rules,
    none = rep("", n_rule),
    id = paste0("R", seq_len(n_rule)),
    weight = formatC(r[[weight]], format = "g", digits = 2),
    size = formatC(r[[size_by]], format = "g", digits = 2),
    both = paste0(formatC(r[[size_by]], format = "g", digits = 2), "\n",
                  formatC(r[[weight]], format = "g", digits = 2)),
    rule = paste(r$antecedent, "=>", r$consequent),
    stop("`label_rules` must be FALSE, TRUE, one of \"none\", \"id\", ",
         "\"weight\", \"size\", \"both\", \"rule\", or a character ",
         "vector one per rule.", call. = FALSE)
  )
}


#' @noRd
.dr_scale <- function(values, range_out) {
  if (length(values) == 0L) return(numeric(0))
  rng <- range(values, na.rm = TRUE)
  if (diff(rng) == 0) return(rep(mean(range_out), length(values)))
  range_out[1L] + (values - rng[1L]) / diff(rng) * diff(range_out)
}


#' Draw the Size and Colour Key for a Rule Network
#'
#' cograph's legend covers discrete groups, edge colours and a node-size
#' scale, but not the two continuous encodings an association-rule graph
#' uses. This draws that key onto the current plot after
#' [cograph::splot()] has run.
#'
#' @param net A rule-level network from [as_network()] with
#'   `level = "rule"`.
#' @param position Corner for the key: `"bottomleft"` (default),
#'   `"bottomright"`, `"topleft"`, `"topright"`.
#' @param cex Text size. Default `0.75`.
#' @return `net`, invisibly.
#' @examples
#' fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
#'                  min_support = 0.3, min_confidence = 0.3)
#' net <- as_network(fit, level = "rule")
#' if (requireNamespace("cograph", quietly = TRUE)) {
#'   cograph::splot(net)
#'   rule_key(net)
#' }
#' @seealso [as_network()]
#' @export
rule_key <- function(net, position = c("bottomleft", "bottomright",
                                       "topleft", "topright"),
                     cex = 0.75) {
  stopifnot(inherits(net, "dynarules_net"))
  position <- match.arg(position)
  rg <- net$meta$ranges
  if (is.null(rg)) {
    stop("rule_key() needs a rule-level network; build one with ",
         "as_network(x, level = \"rule\").", call. = FALSE)
  }
  fmt <- function(v) sprintf("%.3g \u2013 %.3g", v[1L], v[2L])
  graphics::legend(
    position,
    legend = c(sprintf("Size:   %s (%s)", net$meta$size_by, fmt(rg$size)),
               sprintf("Colour: %s (%s)", net$meta$weight, fmt(rg$colour))),
    bty = "o", box.col = "grey60", bg = "white", cex = cex,
    text.col = "grey20", x.intersp = 0, y.intersp = 1.1)
  invisible(net)
}
