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

## Part 3 · Tombstones under churn at 95% live load

```matlab
results3 = part3_tombstone_churn();
```

Each trial fills 9,500 of 10,000 slots and then runs 10,000 delete-and-insert
cycles. A delete removes a random live key and leaves a tombstone. The new
key reuses the first tombstone on its probe path, or takes the first empty
slot if it reaches one first. The live load stays at exactly 95% throughout.
A missing-key lookup treats tombstones as occupied, so it scans until a truly
empty slot. Results go to `part3_tombstone_results.csv` and
`part3_tombstone_churn.png` (30 trials, seed 376).

Empty slots can only decrease: a delete never frees a slot, and an insert
either reuses a tombstone or uses up an empty slot. The tombstone count
approaches 500, the number of non-live slots, and the cost of a miss climbs
toward a full scan of the table (10,000 probes).

## Part 4 · Periodic rebuild versus tombstones

```matlab
results4 = part4_rebuild_compare();
```

Two tables see the same keys, homes and deletions in the same order. Table A
keeps its tombstones. Table B is cleared and its live keys are reinserted
every `rebuildEvery` cycles (1,000 by default). The function counts the
probes spent on rebuilds and churn inserts, and the miss probes saved. It
also prints the number of unsuccessful lookups per cycle at which rebuilding
pays for itself. Results go to `part4_rebuild_results.csv` and
`part4_rebuild_compare.png` (30 trials, seed 377).
