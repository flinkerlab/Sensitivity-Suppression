
function reading_with_DAF_v7_Sentences(subject, block)
% Task runs word reading with delayed auditory feedback

% subjCode = subject identifier (number only)
% blkn = block number

% flog = text file identifier
% AudPnt = psychtoolbox audio
% VidPtr = psychtoolbox window
% pathnameR = pathname of task
% stim_name = name of folder where stimuli are located

% clc; clear; warning off;
% Screen('Preference', 'SkipSyncTests', 1);

% Global variables
global flog AudPnt VidPtr subjCode pathnameR blkn

subjCode = subject;
blkn = block;

% Path to the directory
pathnameR = [pwd '/'];
% cd(pathnameR)
% addpath(pathnameR);

% Make text file
[y,m,d,h,mi,~] = datevec(now);
logfileTxt = sprintf('Reading_with_DAF_Subj%d_Date%d-%d-%d_Time%d-%d.txt',subjCode,y,m,d,h,mi);
flog = fopen(logfileTxt,'w');
if flog < 0, warning('Could not open logfile for writing, reverting to stdout'); flog = 1; end

% Initialize audio and screen handle
my_PsychInit()


if blkn == 0
    % Draw instructions for word reading practice
    DrawFormattedText(VidPtr, ['You will see a sentence on the screen.\n'...
        'Please read the sentence outloud.\n\n'...
        'Let''s start with a practice run first.'],'center', 'center', [255 255 255]);
    Screen(VidPtr,'Flip');
    KbWait(-1);
    [keyDown, secs, keyCode] = KbCheck(-1);
    WaitSecs(0.5);
    
    % PRACTICE RUN
    stim_name = 'sentences_practice';
    repetition = 1; % Repetition per run
    wordreading(blkn, stim_name, repetition)
    
    WaitSecs(0.5);
    % Draw questions for word reading practice run
    Screen('FillRect',VidPtr,0);
    Screen('Flip',VidPtr);
    DrawFormattedText(VidPtr, ['Thank you!\n'...
        'You have completed the practice run.\n\n'...
        'Do you have any questions?'],'center','center',[255 255 255]);
    Screen(VidPtr,'Flip');
    KbWait(-1);
   [keyDown, secs, keyCode] = KbCheck(-1);
    WaitSecs(0.5);
    
    
elseif blkn == 1
    % FIRST RUN
    blkn = 1;
    stim_name = 'sentences';
    repetition = 4;
    wordreading(blkn, stim_name, repetition)
    
    WaitSecs(0.5);
    Screen('FillRect',VidPtr,0);
    Screen('Flip',VidPtr);
    DrawFormattedText(VidPtr, ['Thank you!\n'...
        'You have completed the first run.'],'center','center',[255 255 255]);
    Screen(VidPtr,'Flip');
    KbWait(-1);
    [keyDown, secs, keyCode] = KbCheck(-1);
    WaitSecs(0.5);
    
else
    % SECOND RUN
    blkn = 2;
    stim_name = 'sentences';
    repetition = 4;
    wordreading(blkn, stim_name, repetition)
    
    WaitSecs(0.5);
    Screen('FillRect',VidPtr,0);
    Screen('Flip',VidPtr);
    DrawFormattedText(VidPtr, ['Thank you.\n'...
        'You have now completed the tasks.'],'center','center',[255 255 255]);
    Screen(VidPtr,'Flip');
    KbWait(-1);
    [keyDown, secs, keyCode] = KbCheck(-1);
    WaitSecs(0.5);
    
end

my_PsychClose()

end

% Word reading task
function wordreading(blkn, stim_name, repetition)

% ITI = inter trial interval (sec)
% pathnameS = file name where stimuli are located
% filenamelist = directory info for folder
% stimlist = filenames of all stimuli
% nTrials = number of stimuli
% Data = structure where data is stored

global flog VidPtr AudPnt subjCode pathnameR;

% Parameters
% Wait for 1 second at the beginning of each trial
ITI = 1; %0.500;

% Get keyboard number
pauseKey = 'p';
resumeKey = 'r';
quitKey = 'q';

% Make stim list
filename = sprintf('%s.txt',stim_name);
stimlist = textread(filename,'%s','delimiter','\n','whitespace','');
delays = [10,200];

stimlist_temp = repmat(stimlist,length(delays),1);
delaylist_temp = zeros(length(stimlist_temp),1);

ii = 1;
j = 1;
while ii<=length(delaylist_temp)
    delaylist_temp(ii) = delays(j);
    ii = ii+1;
    if((ii/j) > length(stimlist))
        j = j+1;
    end
end

stimlist_final = repmat(stimlist_temp,repetition,1);
delaylist = repmat(delaylist_temp,repetition,1);

% This will be used to randomize sentences and latencies
cond = (1:length(stimlist_final))';
select_cond = Shuffle(cond);

nTrials = length(stimlist_final);

% Initialize data structure
clear Data
for trial = 1:nTrials
    Data(trial).filename = [];
    Data(trial).delay = [];
    Data(trial).keys = [];
    Data(trial).RT = [];
    Data(trial).k = [];
    Data(trial).flip = [];
end

% Start the trials
trial = 1;

for r = 1:nTrials
    
    % ITI, blank before image
    Screen('FillRect',VidPtr,0);
    Screen('Flip',VidPtr);
    qKeys(GetSecs,ITI);
    
    % Provide some debug output:
    % PsychPortAudio('Verbosity', 10);
    
    % Prepare sound trigger
    [triggeraudio, ~] = audioread('square.wav');
    triggeraudio(:,2)= zeros(length(triggeraudio),1);
    
    % Play sound trigger
    AudPnt = PsychPortAudio('Open', [], [], 0, [], 2);
    
    PsychPortAudio('FillBuffer', AudPnt, triggeraudio');
    
    PsychPortAudio('Start', AudPnt, 1, 0);
    
    % Done. Stop the capture engine:
    PsychPortAudio('Stop', AudPnt, 1);
    
    % Draw text
    textSize = 50; Screen('TextSize', VidPtr ,textSize);
    DrawFormattedText(VidPtr,stimlist_final{select_cond(trial)},'center','center',255,80);
    [flip.VBLTimestamp, flip.StimulusOnsetTime, flip.FlipTimestamp, flip.Missed, flip.Beampos] = Screen('Flip',VidPtr);
    flip.actualtime = now; % Get date and time. Use datestr(now) to display actual date and time
    
    % CAPTURE and PLAYBACK
    % DELAY SOUND: Delivers back the sound with a delay of reqlatency ms
    
    % Desired auditory feedback latency
    reqlatency = delaylist(select_cond(trial));
    latency = reqlatency/1000;
    
    % Open audio channel for recording, this returns a handle to the audio device:
    % Open the default audio device [], with mode 2 (== Only audio capture),
    % and a required latencyclass of 2 == low-latency mode, as well as
    % a frequency of freq Hz and 2 sound channels for stereo capture.
    painput = PsychPortAudio('Open', [], 2, 2, [], 2);
    
    % Preallocate an internal audio recording buffer with a capacity of 10 seconds:
    PsychPortAudio('GetAudioData', painput, 20);
    
    % Open audio channel for playback: Open default audio device [] for playback (mode 1),
    % low latency (2), freq Hz,stereo output:
    paoutput = PsychPortAudio('Open', [], 1, 2, [], 2);
    
    % Set the volume to half for this demo
    PsychPortAudio('Volume', paoutput, 10);

    % Start audio capture immediately and wait for the capture to start.
    % We set the number of 'repetitions' to zero, i.e. record/play until manually stopped.
    PsychPortAudio('Start', painput, 0, 0, 1);
    
    % Start filling the buffer:
    % Wait for at least 'latency' secs of sound data to become available: This
    % directly defines a lower bound on real feedback latency. It's also a weak
    % point, because waiting longer than 'latency' will increase output latency.
    s = PsychPortAudio('GetStatus', painput);
    while s.RecordedSecs < latency
        WaitSecs(0.0001);
        s = PsychPortAudio('GetStatus', painput);
    end
    
    % Quickly readout available sound and initialize sound output buffer with it:
    [audiodata , ~, ~, capturestart]= PsychPortAudio('GetAudioData', painput);
    
    % Feed everything into the initial sound output buffer:
    PsychPortAudio('FillBuffer', paoutput, audiodata);
    
    % Start the playback engine immediately and wait for start, let it run
    % until manually stopped:
    playbackstart = PsychPortAudio('Start', paoutput, 0, 0, 1);
    
    % Now the playback engine should output the first lat msecs of our sound,
    % while the capture engine captures the next msecs. Compute expected
    % latency. This is what the driver thinks, accuracy depends on the quality
    % of implementation of the underlying sound subsystem, so its dependent on
    % operating system and sound driver/sound hardware:
    actual_delay = (playbackstart - capturestart) * 1000
    desired_latency = latency *1000
    
    % Feedback loop: Runs until keypress
    
    while ~KbCheck
        % Sleep about lat/5 secs to give the engines time to at least capture and
        % output lat/5 secs worth of sound
        WaitSecs(latency/5);
        
        % Get new captured sound data
        [audiodata, ~, ~] = PsychPortAudio('GetAudioData', painput);
        
        % Stream it into our output buffer:
        while size(audiodata, 2) > 0
            
            % Make sure to never push more data in the buffer than it can
            % actually hold, ie. not more than half its maximum capacity:
            fetch = min(size(audiodata, 2), floor(48000 * latency/2));
            
            % Feed data in chunks:
            pushdata = audiodata(:, 1:fetch);
            audiodata = audiodata(:, fetch+1:end);
            
            % Perform streaming buffer refill. As long as we don't push more
            % than a buffer size, the driver will take care of the rest.
            PsychPortAudio('FillBuffer', paoutput, pushdata, 1);
            
        end
        % Done. Next iteration...
    end
    
    [keyIsDown,secs,keyCode] = KbCheck;
    keys = KbName(keyCode);
    
    [k.keyIsDown, k.firstKeyPressTimes, k.firstKeyReleaseTimes, k.lastKeyPressTimes, k.lastKeyReleaseTimes] = KbQueueCheck();
    
    % Done. Stop the capture engine:
    PsychPortAudio('Stop', painput, 1);
    
    % Drain its capture buffer...
    [audiodata offset]= PsychPortAudio('GetAudioData', painput);
    
    PsychPortAudio('Stop', paoutput, 1);
    
    PsychPortAudio('Close');
    
    % Update data
    Data(trial).filename = stimlist_final{select_cond(trial)};
    Data(trial).delay = delaylist(select_cond(trial));
    Data(trial).keys = keys;
    Data(trial).RT = secs;
    Data(trial).k = k;
    Data(trial).flip = flip;
    
    % Save data
    fprintf(flog,'%d\t%s\t%s\t%d\t%s\t%d\t%s\t\n',blkn,stim_name,stimlist_final{select_cond(trial)},delaylist(select_cond(trial)),keyIsDown,secs,datestr(flip.actualtime)); % Write to log file, separate with tabs
    [y,m,d,h,mi,~] = datevec(now); % Saves after each trial
    logfileMat = sprintf('Reading_with_DAF_Subj%d_Block%d_%s_Date%d-%d-%d_Time%d-%d.mat',subjCode,blkn,stim_name,y,m,d,h,mi); % Rewrites every minute
    save(logfileMat,'Data'); % Save mat variables
    
    trial = trial + 1;
    
    % Check if pause button pressed
    if strcmp(keys(1),pauseKey) % PAUSE EXPT
        trial = trial - 1; % Repeat trial
        textSize = 30; Screen('TextSize', VidPtr ,textSize);
        thekey = sopause(k,resumeKey);
        if strcmp(thekey,'-')
            break
        end
    elseif strcmp(keys(1),quitKey) % Quit experiment
        Screen('FillRect',VidPtr,0); Screen('Flip',VidPtr);
        DrawFormattedText(VidPtr, ['Are you sure you want to quit?\n'...
            'Press Y or N'],'center', 'center', [255 255 255]);
        Screen(VidPtr,'Flip');
        [keys, ~, k] = qKeys(GetSecs,-1);
        thekey = keys(1);
        if ismember(thekey,['y' '-'])
            my_PsychClose(); clc;
        elseif ismember(thekey,['n' '-'])
            trial = trial - 1; % Repeat trial
        end
    end
    
end

textSize = 50; Screen('TextSize', VidPtr ,textSize);

end

function [keys RT k] = qKeys(startTime,dur,term)
% Get key press and RT

% startTime: current time in seconds, use GetSecs
% dur: duration to self terminate. if set to -1 then will self terminate
%   after first key press.
% term: if set to 1 then self terminate after max dur if no key pressed.
%   do not set dur to -1 if using this

% keys: key that was pressed
% RT: RT to key press
% k: KbQueueCheck output (pressed, firstPress, firstRelease, etc)

if ~exist('term','var') % if variable term exists does not exist, set to 0
    term = 0;
end

KbQueueCreate(-1); % initialize
KbQueueStart(); % start queue

if (dur == -1)||(term == 1) % terminate after first key press
    while 1 % continous loop until break
        [k.pressed, k.firstPress, k.firstRelease, k.lastPress, k.lastRelease]=...
            KbQueueCheck();
        if k.pressed % if button press exit loop
            break
        end
        if term % if term = 1, self terminate after dur
            if (GetSecs-startTime)>dur % dur reached, exit loop
                break
            end
        end
        WaitSecs(0.001); % loop every millisec
    end
else
    WaitSecs('UntilTime',startTime+dur); % terminate after dur
end

KbQueueStop(); % stop queue

if (dur ~= -1)&&(term == 0)
    [k.pressed, k.firstPress, k.firstRelease, k.lastPress, k.lastRelease]=...
        KbQueueCheck(); % get all key presses from KbQueuestart to stop
end

if k.pressed == 0 % no key was pressed
    keys = 'noanswer';
    RT = GetSecs-startTime; % get reaction time
else
    keys = KbName(k.firstPress); % get name of key
    f = find(k.firstPress);
    RT = k.firstPress(f)-startTime; % get reaction time
end
end

function thekey = sopause(k,resumeKey)

global VidPtr

Screen('FillRect',VidPtr,0);
DrawFormattedText(VidPtr, 'Experiment paused... Press R to resume','center','center',255);
Screen('Flip',VidPtr);
while 1
    [keys RT] = qKeys(GetSecs,90,1);
    thekey = keys(1);
    if ismember(thekey,[resumeKey '-'])
        break
    end
end
end


function my_PsychInit()

% Set up audio
% Setup screen
% Get device number

global VidPtr;

% Perform low-level initialization of the sound driver:
InitializePsychSound(1);

% Setup screen
screenNum = 0; %%%% change to 2 in dual monitor setting
[VidPtr,rect] = Screen('OpenWindow',screenNum);
[xc,yc] = RectCenter(rect);
HideCursor;
black = BlackIndex(VidPtr);
Screen('FillRect',VidPtr,black);

priorityLevel = MaxPriority(['GetSecs'],['KbCheck']);

breakfontsize = Screen('TextSize', VidPtr, 50);

% d = PsychHID('Devices');
% deviceNumber = 3

% disable keyboard input to command window
% ListenChar(2);

end

function my_PsychClose()
% Ok, done. Close engines and exit.
Screen('CloseAll');
ShowCursor;
% ListenChar(0); %re-enable keyabord input to command window
fclose('all');
end


