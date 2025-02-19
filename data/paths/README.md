# Paths files (lists of paths per reference sample)

- Each `.paths` file should contain a list of reference paths from a given reference sample, one path per line
- Each file should have the `.paths` extension, and the sample name provided to `Minigraph-Cactus`, e.g.:

```
GRCh38.paths
CHM13.paths
```

- `vg` has been made available in the `pixi` environment, and can be used to report reference samples in a graph and also generate paths files from a graph, e.g.:

```

# Report reference samples in a graph

pixi run vg paths --reference-paths --metadata -x myGraph.gbz | cut -f3 | tail -n+2 | sort | uniq

# Generate a paths file from a specific reference sample

pixi run vg paths --reference-paths --metadata -x myGraph.gbz | tail -n+2 | awk '$3 == "GRCh38"' | cut -f1 > GRCh38.paths

```
