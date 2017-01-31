% Function: Writes ANALYZE 7.5 volumes.

% Prototype write_analyze_volume_BRIC_multitime(filename,DIM,VOX,DESCRIP,data,type)
%
% where filename:	filename of volume
%	DIM:			image dimensions
%	VOX:			voxel dimensions
%	DESCRIP:		description of data	
%	data:			data(1:dim_x,1:dim_y,z)
%	type:			data type
%
% Reference: ANALYZE Reference Manual. Version 7.5. Biomedical Imaging
% Resource Mayo Foundation. Supplied by CNSoftware. Appendix F. pp.
% IV-17 to IV-20
%
% License: BRIC Apache 2.0-style license
%
% Contributions: Mark E. Bastin <Mark.Bastin@ed.ac.uk>  (initial version in two *.m files: one for the header and other for the data)
%                Maria C. Valdés Hernández <mvhernan@staffmail.ed.ac.uk> (changed some fields formats and increased number of data types)
%                Anna K. Heye <a.k.heye@sms.ed.ac.uk> (added the possibility of managing multitime (i.e. 4D) image series)
%
% Last updated: 24.10.2012 

function write_analyze_volume_BRIC_multitime(filename,DIM,VOX,DESCRIP,data,type)

% Setup data type
switch type
 	case 'uint1'
  		TYPE = 1;
 	case 'uint8'
  		TYPE = 2;
 	case 'short'
  		TYPE = 4;
 	case 'int'
  		TYPE = 8;
 	case 'float'
  		TYPE = 16;
 	case 'double'
  		TYPE = 64;
 	otherwise
  		TYPE = 0;
end

% modification: write all time points (AH)
timepoints=length(data); 

% Number of files in volume
num = size(data{1});
DIM(3) = num(3);

% Write data to image volume data file
img_filename = [filename,'.img'];
fid = fopen(img_filename,'wb');					% Write new img file
if isequal(fid,-1)                           
    errordlg('The image data file could not be opened','File error');
    return;
end;
for k=1:timepoints
    data_single=data{k};
    for i = 1:num(3)
        fwrite(fid,data_single(:,:,i),type);
    end
end
fclose(fid);							% Close .img file

% Opening the .hdr file given the filename

file_length = length(filename);                               
if filename(file_length - 3) == '.' 
	filename = filename(1:(file_length - 4)); 
end            
filename = [filename '.hdr'];
fid = fopen(filename,'w');

if isequal(fid,-1)                           
    errordlg('The header file could not be opened','File error');
    return;
end;

data_type = ['dsr      ' 0];
filename = [filename '                  '];
db_name = [filename(1:17) 0];

% Setting header variables

DIM		= DIM(:)'; if size(DIM,2) < 4; DIM = [DIM 1]; end
VOX		= VOX(:)'; if size(VOX,2) < 4; VOX = [VOX 0]; end
dim		= [3 DIM(1:4) 1 1 1];	
pixdim	= [0 VOX(1:4) 0 0 0];
vox_offset 	= 0;
funused1	= 1;
max_number	= 1; 			% corresponds with glmax in struct image_dimension
min_number	= 0;			% corresponds with glmin in struct image_dimension
bitpix 	= 0;
descrip     = zeros(1,80);
aux_file    = ['none                   ' 0];
origin      = [0 0 0 0 0];


if TYPE == 1;  bitpix = 1;  max_number = 1;       min_number = 0;		end
if TYPE == 2;  bitpix = 8;  max_number = 255;     min_number = 0;		end
if TYPE == 4;  bitpix = 16; max_number = 32767;   min_number = -32768;  end
if TYPE == 16; bitpix = 32; max_number = 65536;   min_number = -65536;  end

if nargin < 6; DESCRIP = 'MCMxxxVI file'; end

d          	= 1:min([length(DESCRIP) 79]);
descrip(d) 	= DESCRIP(d);

status = fseek(fid,0,'bof');                     
if isequal(status,-1)
    errordlg('Error setting a file position indicator for the header','File error');
    return;
end

% Writing data to header file

% Writing (struct) header_key
fwrite(fid,348,		'int32');
fwrite(fid,data_type,	'char' );
fwrite(fid,db_name,	'char' );
fwrite(fid,0,		'int32');
fwrite(fid,0,		'int16');
fwrite(fid,'r',		'char' );
fwrite(fid,'0',		'char' );

% Writing (struct) image_dimension
fseek(fid,40,'bof');

fwrite(fid,dim,		'int16');
fwrite(fid,'mm',	'char' );
fwrite(fid,0,		'char' );
fwrite(fid,0,		'char' );
fwrite(fid,zeros(1,8),	'char' );
fwrite(fid,0,		'int16');
fwrite(fid,TYPE,	'int16');
fwrite(fid,bitpix,	'int16');
fwrite(fid,0,		'int16');
fwrite(fid,pixdim,	'float');
fwrite(fid,vox_offset,	'float');
fwrite(fid,funused1,	'float');
fwrite(fid,0,		'float');
fwrite(fid,0,		'float');
fwrite(fid,0,		'float');
fwrite(fid,0,		'float');
fwrite(fid,0,		'int32');
fwrite(fid,0,		'int32');
fwrite(fid,max_number,	'int32');
fwrite(fid,min_number,	'int32');

% Writing (struct) data_history
fwrite(fid,descrip,	'char');
fwrite(fid,aux_file,    'char');
fwrite(fid,0,           'char');
fwrite(fid,origin,      'uint16');
fwrite(fid,zeros(1,85), 'char');

elements_written   = ftell(fid);  % This must be 348
fclose(fid);


