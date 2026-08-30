# Summary Method for a CBA Classifier

Summary Method for a CBA Classifier

## Usage

``` r
# S3 method for class 'dynarules_cba'
summary(object, ...)
```

## Arguments

- object:

  A `dynarules_cba` object.

- ...:

  Ignored.

## Value

A tidy `data.frame`, one row per rule in the decision list plus a final
row for the default: `position`, `antecedent`, `consequent`, `support`,
`confidence`, `lift`.
