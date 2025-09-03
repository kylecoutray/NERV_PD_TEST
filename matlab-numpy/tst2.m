%% Latency Visualization for Poster
% Uses Vanderbilt colors (black, gold, subtle accents)

clear; close all; clc;

% Data: mean (ms) and standard deviation (ms)
labels = {'Unity→Arduino', 'Arduino→Photodiode', 'Unity→Photodiode'};
means  = [2.10, 28.93, 31.04];
stds   = [1.21, 0.76, 1.41];

% Colors (Vanderbilt Gold and Black)
vandyGold = [206 184 136] / 255;  % Official VU Gold
black     = [0 0 0];

% Create figure
figure('Color', 'w', 'Position', [100 100 700 300]);
hold on;

% Plot horizontal bars (means) with error whiskers (std)
for i = 1:numel(means)
    % Horizontal line for the mean
    plot([0 means(i)], [i i], '-', 'Color', vandyGold, 'LineWidth', 4);
    
    % Marker at the end (mean)
    plot(means(i), i, 'o', 'MarkerSize', 10, ...
        'MarkerFaceColor', black, 'MarkerEdgeColor', black);
    
    % Error bar (std) as whiskers
    line([means(i)-stds(i), means(i)+stds(i)], [i i], ...
        'Color', black, 'LineWidth', 2);
end

% Axes formatting
set(gca, 'YTick', 1:numel(labels), 'YTickLabel', labels, ...
    'YDir', 'reverse', 'FontSize', 14, 'LineWidth', 1.5);
xlabel('Latency (ms)', 'FontSize', 16, 'FontWeight', 'bold');
xlim([0 50]);  % Show 0–50 ms for all
grid on;
box off;

title('Measured Latencies (Mean ± SD)', 'FontSize', 18, 'FontWeight', 'bold');

% Optional: Add total latency as an annotation
text(50, 0.5, sprintf('Unity→Photodiode Total: %.1f ± %.1f ms', means(3), stds(3)), ...
    'FontSize', 14, 'HorizontalAlignment', 'right');

