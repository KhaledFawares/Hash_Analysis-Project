function results = part3_tombstone_churn()
% Measure unsuccessful lookups as keys are replaced at 95% live load.
rng(376, 'twister');

tableSize = 10000;
numLiveKeys = 9500;
numTrials = 30;
cycles = (0:100:10000)';
tombstoneCounts = zeros(numel(cycles), numTrials);
missProbes = zeros(numel(cycles), numTrials);

for trial = 1:numTrials
    % 0 is empty, -1 is a tombstone, and positive values are key IDs.
    slots = zeros(tableSize, 1);
    liveSlots = zeros(numLiveKeys, 1);
    homes = randi(tableSize, numLiveKeys + cycles(end), 1);

    for key = 1:numLiveKeys
        slot = firstAvailable(slots, homes(key));
        slots(slot) = key;
        liveSlots(key) = slot;
    end

    for checkpoint = 1:numel(cycles)
        if checkpoint > 1
            for cycle = cycles(checkpoint-1)+1:cycles(checkpoint)
                % Each entry in liveSlots represents exactly one live key.
                pick = randi(numLiveKeys);
                slots(liveSlots(pick)) = -1;

                key = numLiveKeys + cycle;
                slot = firstAvailable(slots, homes(key));
                slots(slot) = key;
                liveSlots(pick) = slot;
            end
        end

        tombstoneCounts(checkpoint, trial) = nnz(slots == -1);
        missProbes(checkpoint, trial) = meanMissProbes(slots);
    end
end

tombstoneMean = mean(tombstoneCounts, 2);
missMean = mean(missProbes, 2);
missMargin = 1.96 * std(missProbes, 0, 2) / sqrt(numTrials);
results = table(cycles, tombstoneMean, missMean, missMargin, ...
    'VariableNames', {'ReplacementCycles', 'MeanTombstones', ...
    'MeanMissProbes', 'MissCIHalfWidth'});
disp(results([1 11 26 51 end], :));

fig = figure('Name', 'Tombstones at 95% live load');
if exist('theme', 'file'), theme(gcf, 'light'); end % White figures for the report.
subplot(2, 1, 1);
plot(cycles, tombstoneMean);
ylabel('Mean tombstone count');
grid on;

subplot(2, 1, 2);
plot(cycles, missMean, 'b', cycles, ...
    [missMean - missMargin, missMean + missMargin], 'b--');
xlabel('Delete-and-insert cycles');
ylabel('Mean probes per miss');
legend('Trial mean', 'Approx. 95% CI bounds', 'Location', 'northwest');
grid on;

writetable(results, 'part3_tombstone_results.csv');
print(fig, 'part3_tombstone_churn.png', '-dpng', '-r200');
end

function slot = firstAvailable(slots, slot)
% The incoming key is new, so it can reuse the first tombstone it visits.
while slots(slot) > 0
    slot = mod(slot, numel(slots)) + 1;
end
end

function average = meanMissProbes(slots)
tableSize = numel(slots);
empty = find(slots == 0);
if isempty(empty)
    % A missing key must make one full circuit.
    average = tableSize;
    return
end

% Tombstones count as occupied for a miss. Each gap of length d
% contributes probe counts d, d-1, ..., 1 across its start slots.
gap = diff([empty; empty(1) + tableSize]);
average = sum(gap .* (gap + 1) / 2) / tableSize;
end
