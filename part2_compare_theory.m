function comparison = part2_compare_theory(results)
% Compare the Part 1 successful lookup means with Janson and Viola, Eq. 2.1.
tableSize = 10000; % Match tableSize in part1_fresh_table.m.
numKeys = round(results.LoadPercent * tableSize / 100);
loadFactor = numKeys / tableSize;
exactMean = zeros(size(numKeys));

for row = 1:numel(numKeys)
    % Q0(m,n-1) starts with 1. Each new term adds one factor.
    term = 1;
    q = 1;
    for k = 1:numKeys(row)-1
        term = term * (numKeys(row) - k) / tableSize;
        q = q + term;
    end
    exactMean(row) = (1 + q) / 2;
end

largeTableMean = (1 + 1 ./ (1 - loadFactor)) / 2;
differencePercent = 100 * (results.MeanHitProbes - exactMean) ./ exactMean;
comparison = table(results.LoadPercent, results.MeanHitProbes, ...
    exactMean, largeTableMean, differencePercent, 'VariableNames', ...
    {'LoadPercent', 'Simulated', 'ExactMean', 'LargeTableMean', 'DifferencePercent'});
disp(comparison);

figure('Name', 'Successful lookups compared with theory');
plot(results.LoadPercent, results.MeanHitProbes, 'o-', ...
    results.LoadPercent, exactMean, 's--', ...
    results.LoadPercent, largeTableMean, '^:');
xlabel('Load factor (%)');
ylabel('Mean probes for a successful lookup');
legend('Simulation', 'Exact mean for 10,000 slots', ...
    'Large-table approximation', 'Location', 'northwest');
grid on;
end
