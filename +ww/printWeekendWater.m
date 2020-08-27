function out = printWeekendWater(data, format)

if nargin == 1; format = ''; end
dataInCells = table2cell(data);

nDays = size(dataInCells{1, 3}, 2);
nAnimals = height(data);
waterAmounts = reshape([dataInCells{:, 3}], nDays, nAnimals)';
dataInCells = cat(2, dataInCells(:, 1:2), waterAmounts);
%%
columnHeaders = {'  Animal  '; ['  Weight % on ', datestr(now, 'dddd  ')]};
for iDay = 1:nDays
    columnHeaders{iDay+2} = datestr(now+iDay, '  ddd, dd-mmm-yyyy  ');
end
switch format
    case 'png'
        hFig = figure;
        hTable = uitable(hFig, 'Data', dataInCells);
        hTable.ColumnName = columnHeaders;
        %% Fit the table nicely inside the figure
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
        % print(hFig, 'water', '-dpdf', '-r300', '-bestfit')
        
    case 'tsv'
        fid = fopen('~/weekend_water_script/water.tsv', 'wt');
        out = strrep(evalc('disp(dataInCells)'), '\n', '\r');
        fwrite(fid, out);
        fclose(fid);
        %    system('cat ~/weekend_water_script/water.tsv | netcat -w 1 128.40.198.220 9100');
    case 'html'
        dataInCells(cellfun('isempty', dataInCells)) = {' '};
        %     out = ['<table><tr><th>Mouse Name</th><th>% Weight</th>'];
        out = ['<table style="width:100%"><tr><th style="padding:5px">', ...
            strjoin(strip(columnHeaders), '</th><th style="padding:5px">'), '</th></tr>'];
        %     for k = 1:length(nDays)
        %       [~, dayName] = weekday(now+k, 'long');
        %       out = [out, '<th>', dayName, '</th>'];
        %     end
        %     out = [out, '</tr>'];
        for i = 1:size(dataInCells,1)
            out = [out, '<tr><td style="padding:5px">', strjoin(dataInCells(i,:), ...
                '</td><td style="padding:5px">'), '</td></tr>'];
        end
        out = [out, '</table>'];
        %%% FOR DEBUGGING %%%
        save printWeekendWaterVars.mat
        %%%
    otherwise
        %     dataInCells(cellfun('isempty', dataInCells)) = {'--'};
        %     out = [dataInCells, repmat({'\r '}, size(dataInCells,1), 1)];
        %     out = ['\t \t ', strjoin(out','\t \t ')];
        %     out = [strjoin(columnHeaders, '\t \t'), '\r ', out];
        % %    out = strrep(evalc('disp([strtrim(columnHeaders''); dataInCells])'), '\n', '\r');
        % %    out = strrep(out, '\n', '\r');
        
        columnHeaders = cellfun(@strtrim,columnHeaders,'uni',0);
        out = sprintf([repmat('\t%s',1,length(columnHeaders)), '\r'],columnHeaders{:});
        for row = 1:size(dataInCells,1)
            for col = 1:size(dataInCells,2)
                out = [out sprintf('\t%s',dataInCells{row,col})];
            end
            out = sprintf('%s\r', out);
        end
end
