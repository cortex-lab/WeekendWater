function [nDays, fail] = getNumDays()
% GETNUMDAYS Get number of future days using calendar API
%   Get the total number of days off by querying a calendar API for any
%   up-coming bank holidays.  NB: This script doesn't support
%   non-sequential dates (e.g. Saturday, Sunday and Tuesday), or
%   nDaysInFuture > 5.

params = ww.Params;
nDays = params.get('nDaysInFuture');
assert(nDays < 6, 'Cannot post water for more than 5 days in the future')
fail = false;
if isempty(params.get('CAL_API_KEY')) || isempty(params.get('CAL_API_URL'))
    disp('Calendar API not configured; skipping')
    return
end
try
    options = weboptions('MediaType', 'application/json', 'Timeout', 10);
    options.MediaType = 'application/x-www-form-urlencoded';
    V = datevec(now); % Get current date to query this year's holidays
    % Construct endpoing URL
    fullEndpoint = sprintf('%s?country=%s&year=%d&region=%s&api_key=%s', ...
        params.get('CAL_API_URL'), params.get('CAL_Country'), V(1), ...
        params.get('CAL_Region'), params.get('CAL_API_KEY'));
    data = webread(fullEndpoint, options);
    if params.get('Mode') > 0 % Print URL and response code
        fprintf('GET %d %s %s %s', ...
            data.meta.code, ...
            params.get('CAL_API_URL'), ...
            params.get('CAL_Country'), ...
            params.get('CAL_Region'))
    end
    holidays = data.response.holidays;
    
    % Filter out impertinant dates
    bank_holiday = cellfun(@(type) any(endsWith(type, 'holiday')) ,{holidays.type});
    regional = strcmp({holidays.locations}, 'All');
    if strcmp(params.get('CAL_Region'), 'England')
        % Exclude Scottish holidays, etc.
        regional = regional | contains({holidays.locations}, 'ENG');
    end
    holidays = holidays(bank_holiday & regional);
    % Convert to datenum
    holidays = cellfun(@(s) datenum(s.iso, 'yyyy-mm-dd'), {holidays.date});
    % Add any holidays coming in the next week
    nDays = nDays + sum(holidays-now < 5 & holidays-now > 0);
catch ex
    warning(ex.identifier, '%s', ex.message)
    fail = true;
end
