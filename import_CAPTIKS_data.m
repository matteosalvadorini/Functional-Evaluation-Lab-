%% Acceleration Import

clear all
close all 
clc

% select the folder containing all the acceleration files (cpk_devices)
folder = uigetdir(pwd, 'Select folder containing CSV files');
if folder == 0
    error('No folder selected.');
end

% find csv files
files = dir(fullfile(folder, '*.csv'));
if isempty(files)
    warning('No CSV files found in the selected folder.');
end

% container struct
T = struct();

for k = 1:numel(files)
    fname = files(k).name;
    fullpath = fullfile(folder, fname);
    try
        tbl = readtable(fullpath);                 % read CSV into table
    catch ex
        warning('Failed reading %s: %s', fname, ex.message);
        continue
    end

    % create valid variable/field name from filename without extension
    [~, name] = fileparts(fname);
    varname = matlab.lang.makeValidName(name);

    % store in struct
    T.(varname) = tbl;

    % also assign to base workspace with that name (optional)
    assignin('base', varname, tbl);
end

% optionally display what was imported
disp('Imported tables:');
disp(fieldnames(T));

%% Anatomical angles Import

% Select the cpk_anatomical_angles....cvs file 
[filename, pathname] = uigetfile('*.csv', 'Select a CSV file');
if isequal(filename,0) || isequal(pathname,0)
    error('No file selected.');
end

% Full path
fullpath = fullfile(pathname, filename);

% Read CSV into table (modify opts if needed)
try
    tbl = readtable(fullpath);
catch ME
    error('Failed to read CSV: %s', ME.message);
end

% Create a valid MATLAB variable name from filename (without extension)
[~, name] = fileparts(filename);
varname = matlab.lang.makeValidName(name);

% Assign table to base workspace with that name
assignin('base', varname, tbl);

% Display result
fprintf('Imported "%s" into workspace as variable "%s".\n', filename, varname);