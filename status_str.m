function [ status_message ] = status_str( status_code )
%   This function returns an status message given the status code.
%   All functions from BRIClib return/exit giving one of the status codes contained by this function.
%   
%   INPUTS: status_code: a signed integer
%
%   OUTPUTS: status_message: a string for display purposes
%
%   author/feedback to: Maria C. Valdés Hernández     <mvhernan@staffmail.ed.ac.uk> ,    July 2014
%

switch status_code
    case -1
        status_message = 'The image data file could not be opened';
    case -2
        status_message = 'The header file could not be opened';
    case -3
        status_message = 'Error setting a file position indicator for the header';
    case 0
        status_message = 'Operation successful';
    case 1
        status_message = 'The dimensions of the image data are different from those specified in the header';
    case 2
        status_message = 'Illegal session error';
    case 3
        status_message = 'Illegal image data type';
    case 4
        status_message = 'Illegal file type';
    case 5
        status_message = 'Can not create temporary storage space';
    case 6
        status_message = 'Only data with 2,3 or 4 dimensions are accepted. Please, check header and data array dimensions';
    case 7
        status_message = 'Differences between the dimensions of the 2 volumes';
    case 8
        status_message = 'Error in the input parameters : number or type';
    otherwise
        if status_code > 40
            status_message = 'Number of bytes in the header is not 348';
        end
        
    
end

