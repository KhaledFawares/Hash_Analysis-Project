function results = part4_rebuild_compare()
% Compare tombstone churn with and without periodic rebuilds at 95% live load.
% Both tables see the same keys, homes, and deletions in the same order.
rng(377, 'twister');

tableSize = 10000;
numLiveKeys = 9500;
numTrials = 30;
numCycles = 10000;
rebuildEvery = 1000; % Rebuild table B after every this many cycles.
cycles = (0:100:numCycles)';

missKeep = zeros(numel(cycles), numTrials);
missRebuild = zeros(numel(cycles), numTrials);
insertKeep = zeros(numTrials, 1);    % Probes spent on churn inserts, table A.
insertRebuild = zeros(numTrials, 1); % Probes spent on churn inserts, table B.
rebuildWork = zeros(numTrials, 1);   % Probes spent reinserting during rebuilds.

for trial = 1:numTrials
    % 0 is empty, -1 is a tombstone, and positive values are key IDs.
    homes = randi(tableSize, numLiveKeys + numCycles, 1);
    picks = randi(numLiveKeys, numCycles, 1);

    slotsA = zeros(tableSize, 1);
    for key = 1:numLiveKeys
        slotsA(firstAvailable(slotsA, homes(key))) = key;
    end
    slotsB = slotsA;
    liveKeys = (1:numLiveKeys)';
    whereA = locate(slotsA, numLiveKeys);
    whereB = whereA;

    missKeep(1, trial) = meanMissProbes(slotsA);
    missRebuild(1, trial) = meanMissProbes(slotsB);

    for cycle = 1:numCycles
        pick = picks(cycle);
        oldKey = liveKeys(pick);
        newKey = numLiveKeys + cycle;

        slotsA(whereA(oldKey)) = -1;
        [slot, probes] = firstAvailable(slotsA, homes(newKey));
        slotsA(slot) = newKey;
        whereA(newKey) = slot;
        insertKeep(trial) = insertKeep(trial) + probes;

        slotsB(whereB(oldKey)) = -1;
        [slot, probes] = firstAvailable(slotsB, homes(newKey));
        slotsB(slot) = newKey;
        whereB(newKey) = slot;
        insertRebuild(trial) = insertRebuild(trial) + probes;

        liveKeys(pick) = newKey;

        if mod(cycle, rebuildEvery) == 0
            % Clear table B and reinsert the live keys in their original order.
            slotsB = zeros(tableSize, 1);
            for key = sort(liveKeys)'
                [slot, probes] = firstAvailable(slotsB, homes(key));
                slotsB(slot) = key;
                whereB(key) = slot;
                rebuildWork(trial) = rebuildWork(trial) + probes;
            end
        end

        checkpoint = find(cycles == cycle, 1);
        if ~isempty(checkpoint)
            missKeep(checkpoint, trial) = meanMissProbes(slotsA);
            missRebuild(checkpoint, trial) = meanMissProbes(slotsB);
        end
    end
end

missKeepMean = mean(missKeep, 2);
missRebuildMean = mean(missRebuild, 2);
results = table(cycles, missKeepMean, missRebuildMean, ...
    missKeepMean - missRebuildMean, 'VariableNames', ...
    {'ReplacementCycles', 'MissProbesNoRebuild', 'MissProbesRebuild', ...
    'SavedPerMiss'});
disp(results(1:10:end, :));

% Each checkpoint stands for the 100 cycles before it. If L misses happen
% per cycle, rebuilding saves L * missSavedPerUnitRate probes in total.
missSavedPerUnitRate = mean(sum(missKeep(2:end, :) - missRebuild(2:end, :), 1)) * 100;
extraWork = mean(rebuildWork + insertRebuild - insertKeep);
fprintf('Rebuild every %d cycles, %d trials:\n', rebuildEvery, numTrials);
fprintf('  Mean rebuild probes per trial:          %.0f\n', mean(rebuildWork));
fprintf('  Mean churn-insert probes, no rebuild:   %.0f\n', mean(insertKeep));
fprintf('  Mean churn-insert probes, with rebuild: %.0f\n', mean(insertRebuild));
fprintf('  Miss probes saved per (miss per cycle): %.0f\n', missSavedPerUnitRate);
fprintf('  Break-even: %.3f unsuccessful lookups per cycle\n', ...
    extraWork / missSavedPerUnitRate);

fig = figure('Name', 'Periodic rebuild versus tombstones');
if exist('theme', 'file'), theme(gcf, 'light'); end % White figures for the report.
semilogy(cycles, missKeepMean, '-', cycles, missRebuildMean, '-');
xlabel('Delete-and-insert cycles');
ylabel('Mean probes per miss (log scale)');
legend('Tombstones only', sprintf('Rebuild every %d cycles', rebuildEvery), ...
    'Location', 'northwest');
grid on;

writetable(results, 'part4_rebuild_results.csv');
print(fig, 'part4_rebuild_compare.png', '-dpng', '-r200');
end

function [slot, probes] = firstAvailable(slots, slot)
% The incoming key is new, so it can reuse the first tombstone it visits.
probes = 1;
while slots(slot) > 0
    slot = mod(slot, numel(slots)) + 1;
    probes = probes + 1;
end
end

function where = locate(slots, numKeys)
% Map each key ID to its slot. Later key IDs are added as they arrive.
where = zeros(numKeys, 1);
occupied = find(slots > 0);
where(slots(occupied)) = occupied;
end

function average = meanMissProbes(slots)
% Same rule as Part 3: tombstones count as occupied for a miss.
tableSize = numel(slots);
empty = find(slots == 0);
if isempty(empty)
    average = tableSize;
    return
end
gap = diff([empty; empty(1) + tableSize]);
average = sum(gap .* (gap + 1) / 2) / tableSize;
end
