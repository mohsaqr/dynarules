# Plot Method for dynarules_boot

Rules ordered by recovery, showing the bootstrap lift interval per rule
and each rule's recovery proportion.

## Usage

``` r
# S3 method for class 'dynarules_boot'
plot(x, top = 20L, ...)
```

## Arguments

- x:

  A `dynarules_boot` object.

- top:

  Integer. Plot the top N rules by recovery. Default 20.

- ...:

  Ignored.

## Value

A `ggplot` object, invisibly.
