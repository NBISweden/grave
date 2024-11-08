# Specify reference paths file

- Pangenome graphs made with `Minigraph-Cactus` contain at least one reference path

- Some processes in this workflow have options that can take one or more reference paths at input, for example when surjecting reads mapped to a graph to one or all linear reference paths

- Users can specify which reference paths to use by placing a text file with a `.paths` extension in this directory

- Each line specifies one reference path found in the graph, e.g.:

```
simChimp#0#simChimp.chr6
simGorilla#0#simGorilla.chr6
```

- _Note_: If the graph has a single reference path, there is no need to create a `.paths` file - by default the pipeline will use all available reference paths
