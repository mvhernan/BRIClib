function [ status ] = write_analyze_75(filename,data,hdrinfo)
% Writes a volume in Analyze 7.5 format. This function uses the header
% struct that the function analyze75info gives as output.
% 
% Inputs:
% filename: path and name of the file to write. Notice that the file extension should not be included.
% data: a 3D or 4D array with the volumetric image data
% hdrinfo: the struct with the header information (http://eeg.sourceforge.net/ANALYZE75.pdf)
%           
% Output:
% A number indicating if the writing was successful or not
% status = -1 indicates that the image file could not be opened
% status = -2 indicates that the header file could not be opened
% status = -3 indicates error setting a file position indicator for the header
% status = 0 indicates that there were no errors writing the .img and .hdr files
% status = 1 indicates that the dimensions of the data are different from those specified in the header
% status = 2 indicates illegal session error
% status = 3 indicates illegal image data type
% status > 3 indicates the number of bytes written in the header, if this is not 348
%
% Note: this function has been tested in matlab R2012b for 3D and 4D image data
%
% Maria C. Valdés Hernández 01.07.2014
% <mvhernan@staffmail.ed.ac.uk> <maria.c.valdeshernandez@gmail.com>


status = 0; 
% setup data type

switch hdrinfo.ImgDataType
 	case 'DT_NONE'
  		TYPE = 0;
 	case 'DT_UNKNOWN'
  		TYPE = 0;
 	case 'DT_BINARY'
  		TYPE = 1;
        datatype = 'uint1';
        hdrinfo.BitDepth = 1;
 	case 'DT_UNSIGNED_CHAR'
  		TYPE = 2;
        datatype = 'uint8';
        hdrinfo.BitDepth = 8;
 	case 'DT_SIGNED_SHORT'
  		TYPE = 4;
        datatype = 'short';
        hdrinfo.BitDepth = 16;
 	case 'DT_SIGNED_INT'
  		TYPE = 8;
        datatype = 'int';
        hdrinfo.BitDepth = 32;
    case 'DT_FLOAT'
  		TYPE = 16;
        datatype = 'float';
        hdrinfo.BitDepth = 32;
 	case 'DT_COMPLEX'
  		TYPE = 32;
        hdrinfo.BitDepth = 64;
 	case 'DT_DOUBLE'
  		TYPE = 64;
        datatype = 'double';
        hdrinfo.BitDepth = 64;
 	case 'DT_RGB'
  		TYPE = 128;
        hdrinfo.BitDepth = 24;
 	case 'DT_ALL'
  		TYPE = 255; 
    otherwise
        status = 3;
        return;
end

% Write data to image volume data file
img_filename = [filename,'.img'];
fid = fopen(img_filename,'wb');	% Write new img file
if isequal(fid,-1)                           
    status = -1;    % The .img file could not be opened
    return;
end;

num = size(data); ndim = length(num);
if isequal(ndim,4)
    if (~isequal(num(1),hdrinfo.Dimensions(1)))||(~isequal(num(2),hdrinfo.Dimensions(2)))||...
            (~isequal(num(3),hdrinfo.Dimensions(3)))||(~isequal(num(4),hdrinfo.Dimensions(4)))
        status = 1;     % The data dimensions are unequal to those specified in the header --> header corrupted
    end  
    hdrinfo.Dimensions = num;
    dim	= [4 hdrinfo.Dimensions 1 1 1];
elseif isequal(ndim,3)
    if (~isequal(num(1),hdrinfo.Dimensions(1)))||(~isequal(num(2),hdrinfo.Dimensions(2)))||...
            (~isequal(num(3),hdrinfo.Dimensions(3)))
        status = 1;     % The data dimensions are unequal to those specified in the header --> header corrupted
    end
    hdrinfo.Dimensions = [num 1];
    dim	= [3 hdrinfo.Dimensions 1 1 1];
end

for j =1:hdrinfo.Dimensions(4)
    for i = 1:hdrinfo.Dimensions(3)
        fwrite(fid,data(:,:,i,j),datatype);
    end
end
fclose(fid);        % Close .img file

% Opening the .hdr file given the filename

file_length = length(filename);                               
if filename(file_length - 3) == '.' 
	filename = filename(1:(file_length - 4)); 
end            
filename = [filename '.hdr'];
fid = fopen(filename,'w');

if isequal(fid,-1)                           
    status = -2;    % The .hdr file could not be opened
    return;
end;

fpos = fseek(fid,0,'bof');                     
if isequal(fpos,-1)
     status = -3;   % Error setting a file position indicator for the header
    return;
end

% Checking fields in the header_key (hdrinfo struct)
data_type = ['dsr      ' 0];
filename = [filename '                  '];
if (isequal(hdrinfo.DatabaseName,''))||(length(hdrinfo.DatabaseName)>18) 
    db_name = [filename(1:17) 0];
else
    db_name = hdrinfo.DatabaseName; % This must have 18 characters only
end
if ~isequal(isinteger(hdrinfo.Extents),1) 
    hdrinfo.Extents=0;
end
if ~isequal(isinteger(hdrinfo.SessionError),1) 
    status = 2;
    return;
end

% Writing struct header_key 
fwrite(fid,348,'int32');  % sizeof_hdr
fwrite(fid,data_type,'char' );
fwrite(fid,db_name,'char' );
fwrite(fid,hdrinfo.Extents,'int32'); % extents should be 16384
fwrite(fid,hdrinfo.SessionError,'int16');
fwrite(fid,'r','char' ); % hdrinfo.Regular must be 'r' to indicate all images and volumes are the same size
fwrite(fid,'0','char' ); % unused. In nifti 1.1 it is called "dim_info" and used to encode directions (phase, frequency, slice)

% Checking fields in the struct image_dimension
v1 = hdrinfo.PixelDimensions(1);
v2 = hdrinfo.PixelDimensions(2);
v3 = hdrinfo.PixelDimensions(3);

if isequal(ndim,3)
    pixdim = [v1 v2 v3 1 0 0 0 0]; % float pixdim[8] (32 bytes)
elseif isequal(ndim,4)
    v4 = hdrinfo.PixelDimensions(4);
    pixdim = [v1 v2 v3 v4 0 0 0 0]; 
end

if ~isequal(isinteger(hdrinfo.VoxelOffset),1) 
    hdrinfo.VoxelOffset = 0;
end

if ~isequal(isinteger(hdrinfo.GlobalMax),1) 
    hdrinfo.GlobalMax = int32(max(nonzeros(data)));
end
if ~isequal(isinteger(hdrinfo.GlobalMin),1) 
    glmin = int32(min(nonzeros(data)));
    if glmin < 0
        hdrinfo.GlobalMin = glmin;
    else
        hdrinfo.GlobalMin = 0;
    end
end

if isequal((hdrinfo.CalibrationMax),0) 
    hdrinfo.CalibrationMax = hdrinfo.GlobalMax; % glmax sat 1% or 0 if unused/unread?
end

hdrinfo.CalibrationMin = 0;

% Writing struct image_dimension 
fseek(fid,40,'bof');

fwrite(fid,dim,	'int16');
fwrite(fid,'mm',	'char' ); % hdrinfo.VoxelUnits 
fwrite(fid,0,		'char' ); % 1 byte
fwrite(fid,0,		'char' ); % 1 byte
fwrite(fid,zeros(1,8),	'char' ); % 8 bytes
fwrite(fid,0,		'int16'); % 2 bytes
fwrite(fid,TYPE,	'int16');
fwrite(fid,hdrinfo.BitDepth,'int16'); % bitpix (number of bits per voxel)
fwrite(fid,0,		'int16');  % first slice index. Normally it is zero
fwrite(fid,pixdim,	'float');  % grid spacings (unit per dimension)
fwrite(fid,hdrinfo.VoxelOffset,'float');
fwrite(fid,1,	    'float'); % funused. In nifti 1.1 it is data scaling, slope
fwrite(fid,0,		'float'); % funused. In nifti 1.1 it is data scaling, offset
fwrite(fid,0,		'float'); % funused
fwrite(fid,hdrinfo.CalibrationMax,	'float'); % cal_max , hdrinfo.CalibrationMax
fwrite(fid,hdrinfo.CalibrationMin,	'float'); % cal_min , hdrinfo.CalibrationMin
fwrite(fid,0,		'int32'); % compressed , hdrinfo.Compressed
fwrite(fid,0,		'int32'); % verified , hdrinfo.Verified
fwrite(fid,hdrinfo.GlobalMax,	'int32');
fwrite(fid,hdrinfo.GlobalMin,	'int32');

% Checking data_history
descrip     = zeros(1,80);
if isequal(hdrinfo.Descriptor,'')
    DESCRIP = 'libBRIC file';
else
    DESCRIP = hdrinfo.Descriptor;
end
d          	= 1:min([length(DESCRIP) 79]);
descrip(d) 	= DESCRIP(d);

if isequal(hdrinfo.AuxFile,'') 
    aux_file    = ['none                   ' 0]; % must be 24 bytes
else
    aux_file = hdrinfo.AuxFile;
end

switch hdrinfo.Orientation
    case 'Transverse unflipped'
        orient = 0;
    case 'Coronal unflipped'
        orient = 1;
    case 'Sagittal unflipped'
        orient = 2;
    case 'Transverse flipped'
        orient = 3;
    case 'Coronal flipped'
        orient = 4;
    case 'Sagittal flipped'
        orient = 5;
    case 'Orientation unavailable'
        orient = 6;
    otherwise
        orient = 6; % assumed orientation unavailable
end

originator      = [0 0 0 0 0];  % This is for referring to the origin, but different software interpret it in different ways. 
                                % In the original Analyze format, these are meant to be zero

% Writing data_history (hdrinfo struct)
fwrite(fid,descrip,	'char');
fwrite(fid,aux_file,'char');
fwrite(fid,orient,  'char');
fwrite(fid,originator,  'uint16');
fwrite(fid,zeros(1,85), 'char'); % These are the fields for patient and scan details in Analyze

elements_written   = ftell(fid);  % This must be 348

if isequal(elements_written,348)
    status = 0;
elseif elements_written > 3
    status = elements_written;
end
fclose(fid);


end

