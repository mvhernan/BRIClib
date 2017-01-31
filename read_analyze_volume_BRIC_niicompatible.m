% Function: Reads ANALYZE 7.5 volume files.
%
% Prototype [imagedata,DIM,VOX,type]=read_analyze_volume_BRIC_niicompatible(filename);
%
% where 	imagedata:	ANALYZE volume image data
%           DIM:		image dimensions
%           VOX:		voxel dimensions
%           filename:	filename (with or without extension)
%           type:		image type
%
% Reference: ANALYZE Reference Manual. Version 7.5. Biomedical Imaging
% Resource Mayo Foundation. Supplied by CNSoftware. Appendix F. pp.
% IV-17 to IV-20
%
% License: BRIC Apache 2.0-style license
%
% Contributions: Mark E. Bastin <Mark.Bastin@ed.ac.uk>  (initial version in two *.m files: one for the header and other for the data)
%                Maria C. Valdés Hernández <mvhernan@staffmail.ed.ac.uk> (changed some fields formats and increased number of data types)
%                Benjamin S. Aribisala <Benjamin.Aribisala@ed.ac.uk> (added compatibility with nifti_1 file formats that have been
%                                                                     generated from Analyze 7.5 files)
%                
%
% Last updated: 24.08.2015 

function [imagedata,DIM,VOX,type]=read_analyze_volume_BRIC_niicompatible(filename)

% Checking the extension and getting the filename 

[~, ~, ext_1] = fileparts(filename);
 if strcmpi(ext_1,'.nii')
        filename= [filename(1:end-4) '.nii'];
 else
        filename= [filename(1:end-4) '.hdr'];
 end
 
fid = fopen(filename,'r');

if (fid > 0)

% read (struct) header_key
	fseek(fid,0,'bof');
	sizeof_hdr 	= fread(fid,1,'int32');
	data_type  	= setstr(fread(fid,10,'char'))';
	db_name    	= setstr(fread(fid,18,'char'))';
	extents    	= fread(fid,1,'int32');		% format int
	session_error   = fread(fid,1,'int16');	% format short int
	regular    	= setstr(fread(fid,1,'char'))';
	hkey_un0    = setstr(fread(fid,1,'char'))';

% read (struct) image_dimension
	fseek(fid,40,'bof');
	dim    	= fread(fid,8,'int16');
%	vox_units   = setstr(fread(fid,4,'char'))';
%	cal_units   = setstr(fread(fid,8,'char'))';
    vox_units   = setstr(fread(fid,4,'uchar'))';% (BSA)
	cal_units   = setstr(fread(fid,8,'uchar'))';% (BSA)
    
	unused1	= fread(fid,1,'int16');
	datatype	= fread(fid,1,'ubit16');  % Careful with this!!!! Otherwise always will be int16!!!  (MVH)
	bitpix	= fread(fid,1,'int16');
	dim_un0	= fread(fid,1,'int16');
	pixdim	= fread(fid,8,'float');
	vox_offset	= fread(fid,1,'float');
	funused1	= fread(fid,1,'float');
	funused2	= fread(fid,1,'float');
	funused3	= fread(fid,1,'float');
	cal_max	= fread(fid,1,'float');
	cal_min	= fread(fid,1,'float');
	compressed	= fread(fid,1,'int32');
	verified	= fread(fid,1,'int32');
	glmax		= fread(fid,1,'int32');
	glmin		= fread(fid,1,'int32');

% read (struct) data_history
	fseek(fid,148,'bof');
	descrip	= setstr(fread(fid,80,'char'))';
	aux_file	= setstr(fread(fid,24,'char'))';
	orient	= fread(fid,1,'char');
	origin	= fread(fid,5,'uint16');
	generated	= setstr(fread(fid,10,'char'))';
	scannum	= setstr(fread(fid,10,'char'))';
	patient_id	= setstr(fread(fid,10,'char'))';
	exp_date	= setstr(fread(fid,10,'char'))';
	exp_time	= setstr(fread(fid,10,'char'))';
	hist_un0	= setstr(fread(fid,3,'char'))';
	views		= fread(fid,1,'int32');
	vols_added	= fread(fid,1,'int32');
	start_field	= fread(fid,1,'int32');
	field_skip	= fread(fid,1,'int32');
	omax		= fread(fid,1,'int32');
	omin		= fread(fid,1,'int32');
	smax		= fread(fid,1,'int32');
	smin		= fread(fid,1,'int32');

	fclose(fid);

% Assign the values of the header to the variables that the function must return
	DIM    	= dim(2:5)';
	VOX     	= pixdim(2:5)';
	if DIM(4) 	== 1; DIM = DIM(1:3); end
	if VOX(4) 	== 0; VOX = VOX(1:3); end
	TYPE     	= datatype;  	% Notice that there is data_type and datatype. See ANALYZE(TM) Reference Manual.    

else
    
    errordlg('The header file could not be open for reading','File error');
    return;
end

% Setup data type
switch TYPE
 	case 1
  		type='uint1';
 	case 2
  		type='uint8';
 	case 4
  		type='short';
 	case 8
  		type='int16';
 	case 16
  		type='float';
 	case 64
  		type='double';
 	otherwise
  		['Unsure what data type ...'];
  	return;
end

if TYPE==2 || TYPE==64
    precision = strcat(type,'=>',type);
else
    precision = type;
end

[~, ~, ext_1] = fileparts(filename);
 if strcmpi(ext_1,'.nii')
        filename= [filename(1:end-4) '.nii'];
 else
        filename= [filename(1:end-4) '.img'];
 end

% Reading the image data
fid = fopen(filename,'r');
fseek(fid, vox_offset, 'bof');
data= fread(fid, Inf, precision);
imagedata= reshape(data, DIM);
fclose(fid);
