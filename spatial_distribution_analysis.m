function [ status ] = spatial_distribution_analysis( name_csvfile, outputpath, atlas, test)
%   Given 2 sets of images/masks obtained from n patients and all registered to the standard space, this function
%   generates a voxel-wise p-map that statistically shows whether the vector X formed by the m values of the voxel j on 
%   the first set of volumes is different from the vector Y formed by the m values of the same voxel j on the second set of volumes.
%   the implicit function is the two-sided Wilcoxon rank sum test, implemented by the function ranksum in MATLAB, equivalent to the Mann-Whitney U test: 
%   Being a voxel in the coordinates (x,y,z) of the a dataset i (with i ranging from 1 to n) and X and Y the vectors containing the voxel at a position (x,y,z) 
%   for the n sets of "volume1{i}" and "volume2{i}" respectively, the process can be expressed as:  
%                     [p(x,y,z),h(x,y,z)] = ranksum(volume1{i}(x,y,z)(i=1-->n) ,volume2{i}(x,y,z) (i=1-->n))
%   where p expresses the significance of the differences between the 2 sets of volumes and h indicates the test decision: either a rejection of the null hypothesis 
%   or a failure to reject the null hypothesis at the 5% significance level.
%   It can apply the paired t-test (parametric) or the F test if frequency of occurrence is wanted to be evaluated
%   
%   INPUTS: name_csvfile: full path and filename of a csv file that contains 3 columns: 
%                         first column:  patient ID (a number or an identifier with letters and numbers. e.g. MSS001, ADNI001)
%                         second column: path and filename of the volumes of type "volume1" (e.g. '/V/ADNI_Study/ADNI001/WMH_mask')
%                         third column: path and filename of the volumes of type "volume2" (e.g. '/V/ADNI_Study/ADNI001/Stroke_lesion_mask')
%           outputpath: full path for storing the two volume files: p and h
%           atlas: full path and filename of the atlas used (e.g. 'C:/Program_Files/MATLAB/Temp/MNI152_1mm.nii.gz')
%           test: strings 'Wilcoxon','t-test' or 'Chi-square' are acceptable. The implicit is 'Wilcoxon'
%
%   OUTPUTS: status: an integer that indicates whether the function was successful or not. This can be used with status_str.m to display error
%                    or completion messages
%
%   author/feedback to: Maria C. Valdés Hernández     <mvhernan@staffmail.ed.ac.uk> ,    July 2014
%

    [ID,volume1,volume2]= importfile(name_csvfile); 
    numpatients = length(ID);
    
    status = 0;
    vol1_and_vol2_equal = ones(numpatients,1);

    % The dimensions of the standard brain are (182,218,182)

    X1 = uint8(zeros(182,218,182,numpatients));
    Y1 = uint8(zeros(182,218,182,numpatients));

    p = ones(182,218,182);
    h = zeros(182,218,182);

    X = double(zeros(1,numpatients));
    Y = double(zeros(1,numpatients));

    % First check that the vols that will be evaluated have the same number of voxels
    % (They should, because to perform this, they needed to be previously registered to standard space. This is just to be sure)
    for i=1:numpatients

        vol1_and_vol2_equal(i) = 1;

        %   Initializing dim arrays
        dim1 = [3,1,1,1,1,1,1,1];
        dim2 = [3,1,1,1,1,1,1,1];

        if isequal(exist([volume1{i},'.nii'],'file'),0) && isequal(exist([volume1{i},'.nii.gz'],'file'),0) % The volume 1 does not exist
             vol1_and_vol2_equal(i) = 0;
        else
            vol1info = load_series(volume1{i},0);
            dim1 = vol1info.hdr.dime.dim; 
        end

       if isequal(exist([volume2{i},'.nii'],'file'),0) && isequal(exist([volume2{i},'.nii.gz'],'file'),0) % The file does not exist
             vol1_and_vol2_equal(i) = 0;
        else
            vol2info = load_series(volume2{i},0);
            dim2 = vol2info.hdr.dime.dim; 
       end

        if ~isequal(dim2(2),dim1(2))||~isequal(dim2(3),dim1(3))||~isequal(dim2(4),dim1(4))
            status = 7;
            vol1_and_vol2_equal(i) = 0;
        end

    end

    % Secondly generate the X and Y vectors for each point 
    for i=1:numpatients

        if isequal(vol1_and_vol2_equal(i),1)
            vol1data = load_series(volume1{i},[]);
            vol2data = load_series(volume2{i},[]);
            X1(:,:,:,i)= vol1data(:,:,:);
            Y1(:,:,:,i)= vol2data(:,:,:);        
        end
    end
    
    [xmax,ymax,zmax] = size(vol1data);
    
    % Third generate the p and h values
    for z=1:xmax
        for y=1:ymax
            for x=1:zmax
                X(1,:) = double(X1(x,y,z,:));
                Y(1,:) = double(Y1(x,y,z,:));
                if isequal(strcmp(test,'Chi-square'),1)
                    [h(x,y,z),p(x,y,z)] = vartest2(X(1,:),Y(1,:));
                elseif isequal(strcmp(test,'t-test'),1)
                    [h(x,y,z),p(x,y,z)] = ttest2(X(1,:),Y(1,:));
                else
                    [p(x,y,z),h(x,y,z)] = ranksum(X(1,:),Y(1,:));
                end
                if isnan(p(x,y,z))
                    p(x,y,z) = 1;
                    h(x,y,z) = 0;
                end   
            end
        end
    end

    
    std_space_header = load_series(atlas,0);
    nii.hdr = std_space_header.hdr;
    nii.filetype = 2;
    nii.fileprefix = [outputpath, filesep,'p'];
    nii.machine = std_space_header.machine;
    nii.img = p;
    save_untouch_nii(nii,nii.fileprefix);
    nii.fileprefix = [outputpath, filesep,'h'];
    nii.img = h;
    save_untouch_nii(nii,nii.fileprefix);
   
    
end

