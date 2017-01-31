function [varargout] = load_series(basename, zidx)
% Load NIFTI or Analyze file (.nii.gz, .nii, or .hdr/.img)
% INPUTS: basename - input file name
%         zidx - (i) a vector containing valid slice numbers, or
%                (ii) 0, which means that just the header should be returned, or
%                (iii) [], which means that all slices should be returned
% RETURNS: S - only the image data without the header, or
%              only the header without image data
% EXAMPLE:
% addpath('NIFTI/');
% S = load_series('C:/tests/T1_weighted_image', []);
% [s,status] = load_series('C:/tests/T1_weighted_image', []);
%
% Author: Andreas Glatz (2013) <a.glatz@sms.ed.ac.uk>
% Modified by Maria C. Valdés Hdez. on 14.07.2014 with permission to include status checks 

status = 0;
[path, name, ext] = fileparts(basename);
if strcmp(ext, '.gz')
    [~, name, tmp2] = fileparts(name);
end
if ~isempty(path)
    basename = [ path filesep name ];
else
    basename = name;
end
name = [basename '.hdr'];
fd = fopen(name, 'r');
if fd < 0
    name = [basename '.nii.gz'];
    fd = fopen(name, 'r');
    if fd < 0
        name = [basename '.nii'];
        fd = fopen(name, 'r');
        if fd < 0
            status = 4;
            error(['Unrecognized file type: ' basename]);
        else
            fclose(fd);
            [S] = load_series_core(name, zidx);
        end
    else
        fclose(fd);
        [S,status] = load_nifti_gz_series(name, zidx);
    end
else
    fclose(fd);
    [S,status] = load_series_core(name, zidx);
end
varargout{1} = S;
varargout{2} = status;



function [S,status] = load_nifti_gz_series(name, zidx)
% We prefer files in NIFTI_GZ format since this saves a lot of
% disk space and we have a 'unzip' command. The MATLAB gunzip 
% command is provided by a Java class, so this command requires 'jvm'.
status = 0;
tmp_dir = tempname('.');
[~, msg] = mkdir(tmp_dir);
if ~strcmp(msg, '')
    status = 5;
    error(['Problems creating temporary directory: ' tmp_dir]);
end
try
    % Extract ...
    file_path = char(gunzip(name, tmp_dir));
    % Load ...
    [S,status_core] = load_series_core(file_path, zidx);
    % Cleanup...
    rmdir(tmp_dir, 's');
catch
    status_core = -1;
    error(['Problems reading file: ' name]);   
end


function [S,statusc] = load_series_core(name, zidx)
%
statusc = 0;
if length(zidx) == 1 && ~zidx
    NII = load_untouch_nii(name);
    S = rmfield(NII, 'img'); % we just want the header
else
    NII = load_untouch_nii(name);
    if NII.hdr.dime.dim(1) > 4 % 4D is maximum
        statusc = 6;
        error('load_series:load_series_core:maxdim', ...
              'Input volume has more than 4 dimensions!');
    end
    S = NII.img;
    if ~isempty(zidx)
        S = S(:, :, zidx, :, :);
    end
end



