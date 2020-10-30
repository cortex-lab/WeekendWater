% This script posts some weights to the dev database so that when we run
% the weekend water script in test mode the table will get fully populated.
% One of the mice will not have its weight updated.
params = ww.Params;
% Alyx instance
ai = Alyx('','');
ai.BaseURL = params.get('ALYX_DEV_URL');
ai = ai.login(params.get('ALYX_Login'), params.get('ALYX_Password'));
fprintf('Using test database: %s\n', ai.BaseURL);
% Post weights to test db:
wrSubs = ai.getData(ai.makeEndpoint('water-restricted-subjects'));
% Double-check mice aren't dead (should be done Alyx side)
alive = ai.listSubjects;
wrSubs = wrSubs(ismember({wrSubs.nickname}, alive));
n = params.get('nDaysInFuture');

% Go through posting weights for those that need one
for iSubject = 1:length(wrSubs)
    if iSubject == 3, continue, end % Skip the third mouse
    subject = wrSubs(iSubject).nickname;
    endpnt = sprintf('water-requirement/%s?start_date=%s&end_date=%s', ...
        subject, datestr(now - 1, 'yyyy-mm-dd'), datestr(now + n, 'yyyy-mm-dd'));
    wr = ai.getData(endpnt);
    records = catStructs(wr.records, nan);
    % no weighings found
    if isempty(wr.records) || isnan(records(2).weighing_at)
        % If the mouse weight has no weight for yesterday, post one around
        % 25g, otherwise use yesterday's weight.
        w = iff(isnan(records(1).weighing_at), 24 + rand, records(1).weighing_at);
        d = ai.postWeight(w, subject);
        assert(contains(d.url, 'dev') && w == d.weight)
    end
end

