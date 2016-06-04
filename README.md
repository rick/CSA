### "CSA" from Andrew V. Goldberg's Network Optimization Library

This is a mirror of CSA version 1.2. This tooling is a solver for weighted bipartite matchings. It is useful for finding solutions to instances of [the Assignment Problem](https://en.wikipedia.org/wiki/Assignment_problem).

If you are intended to use this, you will probably also be interested in the add-on [CSA-tools](https://github.com/rick/CSA-tools) library.

### Usage

Familiarity with the original publication (see "Resources" below) is useful. There are a couple of scripts to help with experimenting with things.

```
$ script/setup  # will clean and build all the relevant sources, run this before anything else
```

The `script/run-graphs` ruby script will generate one of four types of data, with the specified number of nodes, run the CSA-Q solver over that data, and deposit a matching file in the designated location:

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

### Resources

 - ["An efficient cost scaling algorithm for the assignment problem [citeseer]"](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.228.3430), the paper documenting this work. A PDF is available at the link.
 - [Andrew Goldberg's Network Optimization Library](http://www.avglab.com/andrew/soft.html), and a link to [the directory where the network optimization software is stored](http://www.avglab.com/andrew/soft/) (as some links are broken).
 - [Andrew V. Goldberg's home page](http://www.avglab.com/andrew/)
 - [DIMACS implementation challenges](http://dimacs.rutgers.edu/Challenges/) - the first challenge covered network flows and matching. **Note:** Google Chrome cannot apparently successfully access the FTP site -- use another client.

### Notes

 - CSA presumes that the graph provided contains a perfect matching. If no such matching exists the solver will either not terminate, or can produce a non-optimal matching. The [CSA-tools](https://github.com/rick/CSA-tools) repo contains tooling to automate the process of converting arbitrary weighted bipartite graphs into augmented graphs which always have a perfect matching (as well as running the CSA solver, and reducing the resulting perfect matching to a matching on the original graph.)
 - There appears to have been a CSA-1.2.1 linked from the [network optimization library page](http://www.avglab.com/andrew/soft.html) but this code seems to have gone missing. Version 1.2 is mirrored here.
 - It appears that the CS2 software is [also mirrored by another individual on GitHub](https://github.com/iveney/cs2) (note this is not "version 2" of CSA, but a different tool).

#### Copyright

Copyright notice(s) can be found in the file [COPYRIGHT](COPYRIGHT.md).
