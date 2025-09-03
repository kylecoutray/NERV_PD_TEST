% TTL_Analysis.m
% -------------------------------------------------------------------------
% Load & align Unity TTL log with Arduino and photodiode pulses,
% compute delays, and generate publication‑quality figures.
% Requires: TTL_LOGS.csv, channel_states.npy, channels.npy, timestamps.npy,
%           readNPY.m on your MATLAB path.
%
% Kyle Coutray | Vanderbilt University | 2025-07-30
% -------------------------------------------------------------------------

%% 1) Setup & Dependencies
clear; close all; clc;
if exist('readNPY','file')~=2
    error(['readNPY not found on your MATLAB path. ', ...
           'Please download the NPY‑MATLAB reader and add it to your path.']);
end

% Color palette (Vandy Gold, Black, Neon Red, Green‑Blue)
cGold   = [218,165,32]/255;
cBlack  = [0,0,0];
cRed    = [1,0,0];
cTeal   = [0,0.7,0.7];

% Figure defaults
fnt      = 'Arial';
fntSize  = 14;
mkrSz    = 36;
lnW      = 1.5;

%% 2) Load & Filter Unity Event Log
T        = readtable('TTL_LOGS.csv');
mask     = ismember(T.Event, {'SampleOn','DistractorOn','TargetOn'});
events   = T(mask,:);
unity_ms = (events.StopwatchTime - events.StopwatchTime(1)) * 1000;

%% 3) Load & Preprocess Photodiode + Arduino Data
states     = readNPY('channel_states.npy');
channels   = readNPY('channels.npy');
timestamps = readNPY('timestamps.npy');  % in samples
fs         = 30000;                     % Hz

% Rising edges
isPhoto = (states>0) & (channels==1);
isArd   = (states>0) & (channels==8);
tsPhoto = double(timestamps(isPhoto)) ./ fs * 1000;
tsArd   = double(timestamps(isArd))   ./ fs * 1000;

% Keep first in each 200 ms cluster
ct      = 200;
keepP   = [true; diff(tsPhoto)>ct];
keepA   = [true; diff(tsArd)>ct];
tsPhoto = tsPhoto(keepP);
tsArd   = tsArd(keepA);

% Pair Arduino → Screen within 200 ms
D     = abs(tsArd(:) - tsPhoto(:)');
d0    = min(D,[],2);
tsArd = tsArd(d0<=ct);

% Zero‑reference all series
unity_ms = unity_ms - unity_ms(1);
photo_ms = tsPhoto  - tsArd(1);
ard_ms   = tsArd    - tsArd(1);

%% 4) Combined Diagnostic Scatter (Original Scale)
figure('Name','Raw Alignment','NumberTitle','off'); hold on;
yU = ones(size(unity_ms));
yA = 1.0005 * ones(size(ard_ms));
yP = 1.0010 * ones(size(photo_ms));

scatter(unity_ms, yU, mkrSz, 'o', ...
    'MarkerFaceColor', cGold, 'MarkerEdgeColor', cGold, ...
    'LineWidth', lnW, 'DisplayName','Unity');
scatter(ard_ms, yA, mkrSz, 'x', ...
    'MarkerEdgeColor', cRed, 'LineWidth', lnW, 'DisplayName','Arduino');
scatter(photo_ms, yP, mkrSz, 's', ...
    'MarkerFaceColor', cTeal, 'MarkerEdgeColor', cTeal, ...
    'LineWidth', lnW, 'DisplayName','Photodiode');

yticks([1 1.0005 1.0010]);
yticklabels({'Unity','Arduino','Photodiode'});
xlim([-1822 22818]);
ylim([0.99981 1.00122]);
xlabel('Time (ms)','FontName',fnt,'FontSize',fntSize);
title('Raw Event Times Across Sources','FontName',fnt,'FontSize',fntSize);
legend('Location','best');
set(gca,'FontName',fnt,'FontSize',fntSize,'LineWidth',1);
box on; hold off;

%% 5) Compute Delays
n      = numel(unity_ms);
Delay1 = nan(n,1);   % Unity → Arduino
Delay2 = nan(n,1);   % Arduino → Screen
DelayT = nan(n,1);   % Unity → Photodiode

for i = 1:n
    [~,iA]     = min(abs(ard_ms - unity_ms(i)));
    jP         = find(photo_ms >= ard_ms(iA), 1);
    Delay1(i)  = ard_ms(iA) - unity_ms(i);
    if ~isempty(jP)
        Delay2(i) = photo_ms(jP) - ard_ms(iA);
        DelayT(i) = photo_ms(jP) - unity_ms(i);
    end
end

fprintf('Unity→Arduino:    mean=%.2f ms, std=%.2f ms\n', mean(Delay1), std(Delay1));
fprintf('Arduino→Photo:    mean=%.2f ms, std=%.2f ms\n', mean(Delay2), std(Delay2));
fprintf('Unity→Photodiode: mean=%.2f ms, std=%.2f ms\n', mean(DelayT), std(DelayT));

%% 6) Delay Histograms (0–50 ms)
delays = {Delay1, Delay2, DelayT};
titles = {'Unity → Arduino Delay', 'Arduino → Screen Delay', 'Unity → Photodiode Delay'};
colors = {cGold, cRed, cTeal};

for i = 1:3
    figure('Name',titles{i},'NumberTitle','off');
    histogram(delays{i}, 'FaceColor',colors{i}, 'EdgeColor','none');
    xlim([0 50]);
    xlabel('Delay (ms)','FontName',fnt,'FontSize',fntSize);
    ylabel('Count','FontName',fnt,'FontSize',fntSize);
    title(titles{i},'FontName',fnt,'FontSize',fntSize);
    set(gca,'FontName',fnt,'FontSize',fntSize,'LineWidth',0.5);
    box on;
end

%% 7) Arduino → Screen Delay Only (Delay2) Quick Plot
figure('Name','Delay2: Arduino→Screen','NumberTitle','off');
histogram(Delay2, ...
    'FaceColor', cRed, ...
    'EdgeColor','none');
xlim([0 50]);
xlabel('Delay (ms)','FontName',fnt,'FontSize',fntSize);
ylabel('Count','FontName',fnt,'FontSize',fntSize);
title('Arduino → Screen Delay', ...
    'FontName',fnt,'FontSize',fntSize);
set(gca,'FontName',fnt,'FontSize',fntSize,'LineWidth',0.5);
box on;

%% 8) Arduino → Screen Delay by Trial (Delay2 Scatter)
figure('Name','Delay2 Scatter by Trial','NumberTitle','off'); hold on;
trialIDs = events.TrialID;
scatter(trialIDs, Delay2, mkrSz, ...
    'MarkerFaceColor', cRed, ...
    'MarkerEdgeColor', cBlack, ...
    'LineWidth', lnW);
xlabel('Trial ID','FontName',fnt,'FontSize',fntSize);
ylabel('Delay (ms)','FontName',fnt,'FontSize',fntSize);
title('Arduino → Screen Delay by Trial','FontName',fnt,'FontSize',fntSize);
ylim([0 50]);
set(gca,'FontName',fnt,'FontSize',fntSize,'LineWidth',0.5);
box on; hold off;
