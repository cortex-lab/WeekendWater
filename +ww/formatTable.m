function out = formatTable(data, format)
% WW.FORMATTABLE Returns and/or saves the water table in a given format
%  Returns tabular data in a number of optional formats.  Note: Only 'html'
%  is currently used and supported.
%
%  Inputs:
%    data (table): A table of Subject names, percent weights and water
%                  amounts for given dates
%    format (char): Formats include 'png', 'tsv', 'html'.  If no format is 
%                   specified, a tab separated string is returned.  If
%                   'tsv' a file is also saved to disk.
%
% TODO Improve debugging mode

if nargin == 1; format = ''; end
dataInCells = table2cell(data);

nDays = size(dataInCells{1, 3}, 2);
nAnimals = height(data);
waterAmounts = reshape([dataInCells{:, 3}], nDays, nAnimals)';
dataInCells = cat(2, dataInCells(:, 1:2), waterAmounts);
columnHeaders = {'  Animal  '; ['  Weight % on ', datestr(now, 'dddd  ')]};
for iDay = 1:nDays
    columnHeaders{iDay+2} = datestr(now+iDay, '  ddd, dd-mmm-yyyy  ');
end
switch lower(format)
    case 'png'
        hFig = figure;
        hTable = uitable(hFig, 'Data', dataInCells);
        hTable.ColumnName = columnHeaders;
        % Fit the table nicely inside the figure
        hTable.Units = 'normalized';
        hTable.FontWeight = 'bold';
        hTable.Position = [0 0 1 1];
        extent = hTable.Extent;
        pos = hTable.Parent.Position;
        pos(1) = 100;
        pos(2) = 100;
        pos(3) = pos(3)*extent(3);
        pos(4) = pos(4)*extent(4);
        hTable.Parent.Position = pos;
        out = print(hFig, 'water', '-dpng', '-r300');        
    case 'tsv'
        filename = fullfile(iff(ispc, getenv('APPDATA'), getenv('HOME')), 'water.tsv');
        fid = fopen(filename, 'wt');
        out = strrep(evalc('disp(dataInCells)'), '\n', '\r');
        fwrite(fid, out);
        fclose(fid);
    case 'html'
        dataInCells(cellfun('isempty', dataInCells)) = {' '};
        % Print the headers
        out = sprintf(...
            '<table style="width:100%%">\n<tr>\n\t<th style="padding:5px">%s</th>\n</tr>',....
            strjoin(strip(columnHeaders), '</th>\n\t<th style="padding:5px">'));
        % Print each row - 
        % NB: Line breaks are essential to avoid 1000 charecter line limit.
        for i = 1:size(dataInCells,1)
            rowStr = sprintf(...
                '\n<tr>\n\t<td style="padding:5px">%s</td>\n</tr>',...
                strjoin(dataInCells(i,:), '</td>\n\t<td style="padding:5px">'));
            out = [out, rowStr];
        end
        out = [out, newline, '</table>'];
        %%% FOR DEBUGGING %%%
        if ww.Params().get('Mode') > 0
            save(fullfile(userpath, 'printWeekendWaterVars.mat'))
        end
        %%%
    otherwise
        columnHeaders = cellfun(@strtrim,columnHeaders,'uni',0);
        out = sprintf([repmat('\t%s',1,length(columnHeaders)), '\r'],columnHeaders{:});
        for row = 1:size(dataInCells,1)
            for col = 1:size(dataInCells,2)
                out = [out sprintf('\t%s',dataInCells{row,col})];
            end
            out = sprintf('%s\r', out);
        end
end
