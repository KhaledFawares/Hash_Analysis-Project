function results = part1_fresh_table()
% Measure linear probing in fresh tables at several load factors.
rng(375, 'twister');

tableSize = 10000;
loads = [0.50; 0.75; 0.90; 0.95];
numTrials = 50;

meanHit = zeros(numTrials, numel(loads));
meanMiss = zeros(numTrials, numel(loads));
longestCluster = zeros(numTrials, numel(loads));

for loadIndex = 1:numel(loads)
    numKeys = round(loads(loadIndex) * tableSize);
    for trial = 1:numTrials
        home = randi(tableSize, numKeys, 1);
        slots = zeros(tableSize, 1);
        hitProbes = zeros(numKeys, 1);

        for key = 1:numKeys
            slot = home(key);
            probes = 1;
            while slots(slot) ~= 0
                slot = mod(slot, tableSize) + 1;
                probes = probes + 1;
            end
            slots(slot) = key;

            % Without deletions or moves, a lookup follows the same path.
            hitProbes(key) = probes;
        end

        emptySlots = find(slots == 0);
        % Include the gap from the last empty slot back to the first.
        runs = diff([emptySlots; emptySlots(1) + tableSize]) - 1;

        % A run of r occupied slots gives miss costs r+1, r, ..., 2.
        % Starting at the empty slot at the end of the run costs 1.
        missProbes = sum((runs + 1) .* (runs + 2) / 2);

        meanHit(trial, loadIndex) = mean(hitProbes);
        meanMiss(trial, loadIndex) = missProbes / tableSize;
        longestCluster(trial, loadIndex) = max(runs);
    end
end

results = table(100 * loads, mean(meanHit, 1)', mean(meanMiss, 1)', ...
    mean(longestCluster, 1)', 'VariableNames', ...
    {'LoadPercent', 'MeanHitProbes', 'MeanMissProbes', 'MeanLongestCluster'});
disp(results);

% Estimate uncertainty from independent tables, one mean per trial.
hitMargin = 1.96 * std(meanHit, 0, 1)' / sqrt(numTrials);
missMargin = 1.96 * std(meanMiss, 0, 1)' / sqrt(numTrials);

figure('Name', 'Fresh hash tables with linear probing');
if exist('theme', 'file'), theme(gcf, 'light'); end % White figures for the report.
subplot(2, 1, 1);
errorbar(results.LoadPercent, results.MeanHitProbes, hitMargin, '-o');
hold on;
errorbar(results.LoadPercent, results.MeanMissProbes, missMargin, '-s');
hold off;
ylabel('Mean probes');
legend('Successful lookup', 'Unsuccessful lookup', 'Location', 'northwest');
grid on;

subplot(2, 1, 2);
plot(results.LoadPercent, results.MeanLongestCluster, '-o');
xlabel('Load factor (%)');
ylabel('Mean longest run (slots)');
grid on;
end
