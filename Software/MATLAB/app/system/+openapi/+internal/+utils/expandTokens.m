function expandTokens(templateFile, outFile, tokens)
    % EXPANDTOKENS Change tokens in string to something else
    %
    % The tokens in the template file should be of the form
    %   %<<TOKEN_NAME>>%
    %
    % The tokens argument is a structure with the TOKEN_NAME entries as
    % fields.

    % Copyright 2020-2024 MathWorks, Inc

    str = fileread(templateFile);

    str = changeTokens(str, tokens);

    % Remove carriage return if any
    str(str==13)=[];
    
    fh = fopen(outFile, 'w');
    if fh < 0
        error('Could not write to: %s\n', outFile);
    end
    closeAfter = onCleanup(@() fclose(fh));

    fprintf(fh, '%s', str);
end

function str = changeTokens(str, tokens)
   fn = fieldnames(tokens);
   for k=1:length(fn)
       F = fn{k};
       V = tokens.(F);
       str = regexprep(str, ['%<<', F, '>>%'], V);
   end
end
