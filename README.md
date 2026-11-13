# Hash_Analysis-Project

Open this folder in MATLAB and run:

```matlab
results = part1_fresh_table();
```

The function prints a summary table and opens a figure. It uses base MATLAB. The table size, load factors, number of trials, and random seed are near the top of the file. The default run builds 50 new tables at each load.

Each distinct key gets one random home slot from `randi`. If that slot is occupied, the key tries the next one. After the last slot, probing wraps back to the first. With one slot per bucket, the load factor is the number of keys divided by the number of slots.

- **Successful lookup.** The program counts every slot visited when inserting each key. A lookup for that key visits those same slots because the key stays where it was placed.
- **Unsuccessful lookup.** A missing key scans from its home slot to the first empty slot. We average over every possible home slot. For example, three occupied slots followed by an empty slot give probe counts of 4, 3, 2, and 1. This includes the home slot and the empty slot where the search stops.
- **Longest cluster.** For each table, we record the longest consecutive run of occupied slots, including runs that wrap around. The summary averages these maxima across trials.

The lookup plot shows approximate 95% confidence intervals for the means. These use the variation across independently generated tables.

This setup follows the one-slot, first-come-first-served case in Janson and Viola's [*A Unified Approach to Linear Probing Hashing with Buckets*](https://arxiv.org/abs/1410.5967), especially Sections 1 and 3. We count the full runs directly. The paper's definition of a cluster includes the non-full bucket that ends the run. Zombie Hashing motivates a later experiment with deletions and tombstones.

## Part 2 · Compare successful lookups with theory

With the Part 1 results still in MATLAB, run:

```matlab
comparison = part2_compare_theory(results);
```

The function prints and plots the simulated means alongside the exact
expectation from Equation (2.1) and the large-table approximation
`(1 + 1/(1 - loadFactor))/2`. The percentage difference is relative to the
exact expectation. If you change the table size, update it in both files.
