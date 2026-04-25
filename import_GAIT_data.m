%% ANGOLI
% Prompt user to pick a file -> angoli.emt
[filename, pathname] = uigetfile({'*.*','All Files (*.*)'}, 'Select file for importAngoli');
if isequal(filename,0) || isequal(pathname,0)
    error('No file selected.');
end

% Build full path and call importAngoli
fullpath = fullfile(pathname, filename);
angles = importAngoli(fullpath, 6, 109);
%Import normality data
normAngles = importAngoliNormali('angoli_normali.emt', 6, 109);
% Assign to base workspace and display confirmation
assignin('base', 'angles', angles);
fprintf('Imported angles from "%s" into variable "angles".\n', filename);

%% FORZE
% Prompt user to pick a file -> forze.emt
[filename, pathname] = uigetfile({'*.*','All Files (*.*)'}, 'Select file for importAngoli');
if isequal(filename,0) || isequal(pathname,0)
    error('No file selected.');
end

% Build full path and call importForze
fullpath = fullfile(pathname, filename);
forces = importForze(fullpath, 6, 109);


% Assign to base workspace and display confirmation
assignin('base', 'forces', forces);
fprintf('Imported angles from "%s" into variable "forces".\n', filename);
% 've' stands for vertical component
% 'ml' stands for medio-lateral component
% 'ap' stands for antero-posterior component

%% POTENZE
% Prompt user to pick a file -> potenze.emt
[filename, pathname] = uigetfile({'*.*','All Files (*.*)'}, 'Select file for importAngoli');
if isequal(filename,0) || isequal(pathname,0)
    error('No file selected.');
end

% Build full path and call importForze
fullpath = fullfile(pathname, filename);
powers = importPotenze(fullpath, 6, 109);
%Import normality data
normPowers = importPotenzeNormali('potenze_normali.emt', 6, 109);

% Assign to base workspace and display confirmation
assignin('base', 'powers', powers);
fprintf('Imported angles from "%s" into variable "powers".\n', filename);

%% MOMENTI
% Prompt user to pick a file -> potenze.emt
[filename, pathname] = uigetfile({'*.*','All Files (*.*)'}, 'Select file for importAngoli');
if isequal(filename,0) || isequal(pathname,0)
    error('No file selected.');
end

% Build full path and call importForze
fullpath = fullfile(pathname, filename);
moments= importMomenti(fullpath, 6, 109);
%Import normality data
normMoments = importMomentiNormali('momenti_normali.emt', 6, 109);


% Assign to base workspace and display confirmation
assignin('base', 'moments', moments);
fprintf('Imported moments from "%s" into variable "moments".\n', filename);