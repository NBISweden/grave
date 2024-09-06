# Pangenome graph reference files

- If `Minigraph-Cactus` was run with `--giraffe --haplo`, run this workflow with `--referenceMode haplo` (the default setting), and place the input files here, e.g.:

```
my-graph.gbz
my-graph.hapl
```

- If `Minigraph-Cactus` was run with `--giraffe` alone (equivalent to `--giraffe --filter 2`), or with an explicit filter threshold (e.g.: `--giraffe --filter 10`), run this workflow with `--referenceMode filter` or edit the default setting in `conf/parameters.config` to `filter`, and place the input files here, e.g.:

```
my-graph.d10.dist
my-graph.d10.gbz
my-graph.d10.min
```
