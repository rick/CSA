# "CSA" from Andrew V. Goldberg's Network Optimization Library

This is a mirror of CSA version 1.2. This tooling is a solver for weighted bipartite matchings. It is useful for finding solutions to instances of [the Assignment Problem](https://en.wikipedia.org/wiki/Assignment_problem).

### Resources

 - ["An efficient cost scaling algorithm for the assignment problem [citeseer]"](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.228.3430), the paper documenting this work. A PDF is available at the link.
 - [Andrew Goldberg's Network Optimization Library](http://www.avglab.com/andrew/soft.html), and a link to [the directory where the network optimization software is stored](http://www.avglab.com/andrew/soft/) (as some links are broken).
 - [Andrew V. Goldberg's home page](http://www.avglab.com/andrew/)
 - [DIMACS implementation challenges](http://dimacs.rutgers.edu/Challenges/) - the first challenge covered network flows and matching. **Note:** Google Chrome cannot apparently successfully access the FTP site -- use another client.

### Notes

 - Out of the box, the DIMACS tooling will not compile on modern operating systems.
 - Out of the box, the CSA software will generate a number of compilation warnings on modern operating systems. It will not compile without modification on Mac OS X.
 - CSA presumes that the graph provided contains a perfect matching. If no such matching exists the solver will either not terminate, or can produce a non-optimal matching. Conjecture: It should suffice to augment graphs to complete bipartite graphs, with added edges having sufficiently large weights as to not be selected in a matching.
 - There appears to have been a CSA-1.2.1 linked from the network optimization library page](http://www.avglab.com/andrew/soft.html) but this code seems to have gone missing. Version 1.2 is mirrored here.
 - It appears that the CS2 software is [also mirrored by another individual on GitHub](https://github.com/iveney/cs2).

#### Copyright

Copyright notice(s) can be found in the file [COPYRIGHT](COPYRIGHT).
