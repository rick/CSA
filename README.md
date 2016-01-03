### "CSA" from Andrew V. Goldberg's Network Optimization Library

This is a mirror of CSA version 1.2. This tooling is a solver for weighted bipartite matchings. It is useful for finding solutions to instances of [the Assignment Problem](https://en.wikipedia.org/wiki/Assignment_problem). The original code has been updated to work with modern C compilers, and additional tooling around the solver has been added.

### Usage

Familiarity with the original publication (see "Resources" below) is useful. There some scripts to help with experimenting with things.

#### Building

```
$ script/setup  # will clean and build all the relevant sources, run this before anything else
```

#### Running the solver on generated graphs

The `script/run-graphs` ruby script will use the original [DIMACS Challenge](http://dimacs.rutgers.edu/Challenges/) graph generator scripts to generate one of four types of graph, with the specified number of nodes; run the CSA-Q solver over that graph, and deposit a results file for the matching in the designated location.

```
$ script/run-graphs
RuntimeError: usage: script/run-graphs [high|low|fixed|dense] <nodecount> <output file>
$ time script/run-graphs high 100000 /tmp/flow.txt

Generating data from template in file [/tmp/template.txt]:

nodes 100000
sources 50000
degree 17
maxcost 100000000
seed 25774

Running CSA-Q solver on data file [/tmp/data.txt]:

===== Precise costs; Stack ordering; Quick minima; NUM_BEST = 3 =====
==========================================================================
|>  n = 100000,  m = 850000,  sc_f = 10
|>   cost    -4536791433318,    time      0.600 seconds
|>   13 refines:     100%     1654286 relabelings
|>                   1004286 double pushes, 2658572 pushes
|>   439039 list rebuilds, 0 full scans, 1215247 avoided scans
==========================================================================
Flow stored in output file: /tmp/output.flow moving to /tmp/flow.txt...
Done.

real	0m1.534s
user	0m1.404s
sys	0m0.127s

$ wc -l /tmp/flow.txt
50000 /tmp/flow.txt
```

### Perfect Matchings

CSA presumes that the graph provided contains a perfect matching. If no such matching exists the solver will either not terminate, or can produce a non-optimal matching. (There are notes in the code to the effect that it would be possible to modify the solver to deal with this case, but that work was apparently never undertaken)

In conversations with Andrew V. Golberg, he provided an algorithm for converting a bipartite graph which might not have a perfect matching into a graph which will have a perfect matching, and from which a solution to the perfect assignment problem on the augmented graph can be transformed into a maximum cardinality minimum cost matching on the original graph.

The algorithm is as follows.

Given a weighted bipartite graph `G`, with `n` vertices and `m` weighted edges, construct an augmented graph `G'` with `2n` vertices and `2m+n` edges:

 - Take the vertices and edges of the original graph `G`, and add a flipped copy of `G`: vertices on the left side copied to the right side, and vice versa. Copy the edges with weights.
 - Add high-cost edges between each original node and its flipped copy.

An illustration may help:

![](docs/images/augmented-matching.png?raw=true)

From the matching on the augmented graph, we can take those original nodes from `G` which matched with other original nodes from `G` as the desired matching. Note that nodes from `G` which matched via high-cost edges (necessarily with their complement nodes in the flipped graph) are unmatched nodes in the solution.

### Resources

 - ["An efficient cost scaling algorithm for the assignment problem [citeseer]"](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.228.3430), the paper documenting this work. A PDF is available at the link.
 - [Andrew Goldberg's Network Optimization Library](http://www.avglab.com/andrew/soft.html), and a link to [the directory where the network optimization software is stored](http://www.avglab.com/andrew/soft/) (as some links are broken).
 - [Andrew V. Goldberg's home page](http://www.avglab.com/andrew/)
 - [DIMACS implementation challenges](http://dimacs.rutgers.edu/Challenges/) - the first challenge covered network flows and matching. **Note:** Google Chrome cannot apparently successfully access the FTP site -- use another client.
 - The documentation on the DIMACS graph format can be found locally in [docs/dimacs_file_format.pdf](docs/dimacs_file_format.pdf).

### Other Distributions

 - There appears to have been a CSA-1.2.1 linked from the [network optimization library page](http://www.avglab.com/andrew/soft.html) but this code seems to have gone missing. Version 1.2 is mirrored here.
 - It appears that the CS2 software is [also mirrored by another individual on GitHub](https://github.com/iveney/cs2) (note this is not "version 2" of CSA, but a different tool).

### Copyright

Copyright notice(s) can be found in the file [COPYRIGHT](COPYRIGHT.md).
