function [] = save_series_raw(NII, basename)
% Save as NIFTI or Analyze file (.nii.gz, .nii, or .hdr/.img)
%
% This is an internal function and it's recommended to use
% the function 'save_series()' instead.

% Author: Andreas Glatz <andi@mingsze.com>
%
do_gzip = false;
[path, name, ext] = fileparts(basename);	
if ~isempty(ext)
    if strcmp(ext, '.gz')
        do_gzip = true;
        if ~isempty(path)
            name_ext = [path filesep name];
        else
            name_ext = name;
        end
    else
        do_gzip = false;
        name_ext = basename;
    end
else
    do_gzip = true;
    name_ext = [basename '.nii'];    
end
save_untouch_nii(NII, name_ext);

try
    if do_gzip
        % Compress and cleanup - needs 'jvm'!
        gzip(name_ext);
        delete(name_ext);
    end
catch
    error(['Could not write file: ' name]);
end
