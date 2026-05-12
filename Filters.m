clc;
clear all;

[x_raw, Fs] = audioread('C:\Users\jawad\OneDrive\Desktop\Video-Project.m4a');

if size(x_raw, 2) > 1
    x = mean(x_raw, 2);
else
    x = x_raw;
end

x = x / max(abs(x));

N    = length(x);
t    = (0 : N-1)' / Fs;
f    = (0:N-1) * (Fs/N);
half = floor(N/2);
duration = N / Fs;


X = fft(x);

%% ============================================================
%%              HIGH PASS FILTER (FFT ONLY)
%%                  Cutoff  : 300 Hz
%% ============================================================
fc_hp = 300;

mask_hp = ones(N, 1);
cutoff_bin_hp = round(fc_hp * N / Fs);

mask_hp(1 : cutoff_bin_hp) = 0;
mask_hp(N - cutoff_bin_hp + 2 : N) = 0;

X_hp = X .* mask_hp;
x_hp = real(ifft(X_hp));

%% ============================================================
%%              LOW PASS FILTER (FFT ONLY)
%%                  Cutoff  : 4000 Hz
%% ============================================================
fc_lp = 4000;

mask_lp = ones(N, 1);
cutoff_bin_lp = round(fc_lp * N / Fs);

mask_lp(cutoff_bin_lp : N - cutoff_bin_lp + 2) = 0;

X_lp = X .* mask_lp;
x_lp = real(ifft(X_lp));

%% ============================================================
%%              NOTCH FILTER (FFT ONLY)
%%                  Center  : 50 Hz
%% ============================================================
f_notch = 50;
bw      = 2;

mask_notch = ones(N, 1);

bin_low  = round((f_notch - bw) * N / Fs);
bin_high = round((f_notch + bw) * N / Fs);

mask_notch(bin_low : bin_high)                  = 0;
mask_notch(N - bin_high + 2 : N - bin_low + 2) = 0;

X_notch = X .* mask_notch;
x_notch = real(ifft(X_notch));

%% ============================================================
%%              BAND PASS FILTER (FFT ONLY)
%%             speech band 300 Hz to 3400 Hz
%% ============================================================
fc_bp_low  = 300;    % lower cutoff (Hz)
fc_bp_high = 3400;   % upper cutoff (Hz)

mask_bp = zeros(N, 1);   % start with all zeros

bin_bp_low  = round(fc_bp_low  * N / Fs);
bin_bp_high = round(fc_bp_high * N / Fs);

% Pass positive frequency band
mask_bp(bin_bp_low : bin_bp_high) = 1;

% Pass mirror negative frequency band
mask_bp(N - bin_bp_high + 2 : N - bin_bp_low + 2) = 1;

X_bp = X .* mask_bp;
x_bp = real(ifft(X_bp));

%% ============================================================
%%         ALL FOUR COMBINED (HPF + LPF + NOTCH + BPF)
%% ============================================================
mask_all = mask_bp .* mask_notch;

X_all = X .* mask_all;
x_all = real(ifft(X_all));



X_hp_spec    = fft(x_hp);
X_lp_spec    = fft(x_lp);
X_notch_spec = fft(x_notch);
X_bp_spec    = fft(x_bp);
X_all_spec   = fft(x_all);

%% ===================== FIGURE 1: TIME DOMAIN =====================
figure;

subplot(6,1,1);
plot(t, x, 'b');
xlabel('Time (s)'); ylabel('Amplitude');
title('Original Noisy Signal - Time Domain');
grid on;

subplot(6,1,2);
plot(t, x_hp, 'r');
xlabel('Time (s)'); ylabel('Amplitude');
title(['HPF - Time Domain  (fc = ' num2str(fc_hp) ' Hz)']);
grid on;

subplot(6,1,3);
plot(t, x_lp, 'm');
xlabel('Time (s)'); ylabel('Amplitude');
title(['LPF - Time Domain  (fc = ' num2str(fc_lp) ' Hz)']);
grid on;

subplot(6,1,4);
plot(t, x_notch, 'Color', [0.85 0.33 0.10]);
xlabel('Time (s)'); ylabel('Amplitude');
title(['Notch - Time Domain  (f = ' num2str(f_notch) ' Hz, bw = +/- ' num2str(bw) ' Hz)']);
grid on;

subplot(6,1,5);
plot(t, x_bp, 'Color', [0.00 0.60 0.80]);
xlabel('Time (s)'); ylabel('Amplitude');
title(['BPF - Time Domain  (' num2str(fc_bp_low) ' Hz to ' num2str(fc_bp_high) ' Hz)']);
grid on;

subplot(6,1,6);
plot(t, x_all, 'g');
xlabel('Time (s)'); ylabel('Amplitude');
title('ALL COMBINED (BPF + Notch) - Cleanest Signal');
grid on;

sgtitle('Time Domain Comparison — All Filters');

%% ===================== FIGURE 2: FREQUENCY DOMAIN =====================
figure;

subplot(6,1,1);
plot(f(1:half), abs(X(1:half)), 'b');
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
title('Original Signal - Frequency Spectrum');
grid on;

subplot(6,1,2);
plot(f(1:half), abs(X_hp_spec(1:half)), 'r');
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
title(['HPF  (fc = ' num2str(fc_hp) ' Hz)']);
grid on;

subplot(6,1,3);
plot(f(1:half), abs(X_lp_spec(1:half)), 'm');
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
title(['LPF  (fc = ' num2str(fc_lp) ' Hz)']);
grid on;

subplot(6,1,4);
plot(f(1:half), abs(X_notch_spec(1:half)), 'Color', [0.85 0.33 0.10]);
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
title(['Notch  (f = ' num2str(f_notch) ' Hz, bw = +/- ' num2str(bw) ' Hz)']);
grid on;

subplot(6,1,5);
plot(f(1:half), abs(X_bp_spec(1:half)), 'Color', [0.00 0.60 0.80]);
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
title(['BPF  (' num2str(fc_bp_low) ' Hz to ' num2str(fc_bp_high) ' Hz)']);
grid on;

subplot(6,1,6);
plot(f(1:half), abs(X_all_spec(1:half)), 'g');
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
title('ALL COMBINED (BPF + Notch)');
grid on;

sgtitle('Frequency Domain Comparison — All Filters');

%% ===================== FIGURE 3: NOTCH ZOOMED IN =====================
figure;

subplot(2,1,1);
plot(f(1:half), abs(X(1:half)), 'b');
xlim([0 150]);
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
title('Original - Zoomed 0 to 150 Hz  (50 Hz hum visible)');
grid on;

subplot(2,1,2);
plot(f(1:half), abs(X_notch_spec(1:half)), 'Color', [0.85 0.33 0.10]);
xlim([0 150]);
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
title('Notch Filtered - Zoomed 0 to 150 Hz  (50 Hz hum removed)');
grid on;

sgtitle('Notch Filter Effect — 50 Hz Powerline Hum');

%% ===================== FIGURE 4: BPF ZOOMED IN =====================
figure;

subplot(2,1,1);
plot(f(1:half), abs(X(1:half)), 'b');
xlim([0 20000]);
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
title('Original - Full Spectrum');
grid on;

subplot(2,1,2);
plot(f(1:half), abs(X_bp_spec(1:half)), 'Color', [0.00 0.60 0.80]);
xlim([0 20000]);
xlabel('Frequency (Hz)'); ylabel('|X(f)|');
title(['BPF - Only ' num2str(fc_bp_low) ' to ' num2str(fc_bp_high) ' Hz band remains']);
grid on;

sgtitle('Band Pass Filter Effect — Speech Band Isolation');

%% ===================== PLAY ALL SIGNALS =====================
disp('Playing ORIGINAL noisy signal...');
sound(x, Fs);
pause(duration + 0.2);

disp('Playing HPF filtered (low noise removed)...');
sound(x_hp, Fs);
pause(duration + 0.2);

disp('Playing LPF filtered (high noise removed)...');
sound(x_lp, Fs);
pause(duration + 0.2);

disp('Playing NOTCH filtered (50 Hz hum removed)...');
sound(x_notch, Fs);
pause(duration + 0.2);

disp('Playing BPF filtered (speech band 300-3400 Hz isolated)...');
sound(x_bp, Fs);
pause(duration + 0.2);

disp('Playing ALL COMBINED - cleanest signal...');
sound(x_all, Fs);
pause(duration + 0.2);

disp('Done.');