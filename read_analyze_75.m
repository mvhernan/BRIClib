function [data,hdrinfo] = read_analyze_75(filename)

% Reads volumes in Analyze 7.5 format. This function uses the MATLAB
% functions analyze75info and analyze75read that are part of the Image
% Processing Toolbox
% 
% Input: path and name of the file to read, in Analyze 7.5 format. 
%        Notice that the file extension should not be included.
% Outputs: the struct hdrinfo with the header information (http://eeg.sourceforge.net/ANALYZE75.pdf)
%          the image data in a 3D or a 4D array.  
%
% Note: this function has been tested in matlab R2012b for 3D and 4D image data
%
% Maria C. Valdés Hernández 01.07.2014
% <mvhernan@staffmail.ed.ac.uk> <maria.c.valdeshernandez@gmail.com>

hdrinfo = analyze75info(filename);
data = analyze75read (hdrinfo);

dim = hdrinfo.Dimensions;
for t=1:dim(4)
    for z=1:dim(3)     
        data(:,:,z,t) = rot90(fliplr(data(:,:,z,t)));
    end
end


