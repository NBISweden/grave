# Pangenome graph

Reference pangenome graph in `gbz` format.

## To run with haplotype sampling (best practices)

The graph is made using Minigraph-Cactus with the `--haplo` option.

Provide the clipped, unfiltered graph, e.g.: `graph.gbz`.

## To run on filtered graphs

The graph is made using Minigraph-Cactus with the `--giraffe` option, which filters to a default depth of 2 (depth is adjusted with the `--filter` option, e.g.: `--giraffe --filter 10`).

Provide the clipped, filtered graph, e.g.: `graph.d2.gbz`.
