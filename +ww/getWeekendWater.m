function [data, skipped] = getWeekendWater(ai, nDaysInFuture, exclude)
% WW.GETWEEKENDWATER Builds a table of water amounts and posts to Alyx
if nargin<2
    nDaysInFuture = 2;
end
if nargin<3
    exclude = struct;
end
if nargin < 1 || isempty(ai) || ~ai.IsLoggedIn
    ai = Alyx;
end

wrSubs = ai.getData(ai.makeEndpoint('water-restricted-subjects'));
% Double-check mice aren't dead (should be done Alyx side)
alive = ai.listSubjects;
wrSubs = wrSubs(ismember({wrSubs.nickname}, alive));

nSubjects = length(wrSubs);
animalName = cell(nSubjects, 1);
prcWeightToday = cell(nSubjects, 1);
giveWater = cell(nSubjects, nDaysInFuture);
skipped = [];

%%% FOR DEBUGGING %%%
waterValues = cell(nSubjects, 2);
advancedPost = true(nSubjects,nDaysInFuture);
%%%
for iSubject = 1:nSubjects
    subject = wrSubs(iSubject).nickname;
    animalName{iSubject} = subject;
    endpnt = sprintf('water-requirement/%s?start_date=%s&end_date=%s', subject, datestr(now, 'yyyy-mm-dd'), datestr(now+nDaysInFuture, 'yyyy-mm-dd'));
    wr = ai.getData(endpnt);
    records = catStructs(wr.records, nan);
    % no weighings found
    if isempty(wr.records) || isnan(records(1).weighing_at)
        fprintf('No weight data found for subject %s, skipping\n', subject);
        user = getOr(ai.getData(['subjects/',subject]), 'responsible_user'); %TODO Deal with multiusers
        skipped = [skipped, struct('subject', subject, 'user', user)];
        waterValues{iSubject, 1} = "Skipped";
        waterValues{iSubject, 2} = "Skipped";
        prcWeightToday{iSubject} = 'Unknown';
        %[giveWater{iSubject, :}] = deal('-'); % Leave black for users to fill in
        continue
    end
    weightPrc = records(1).percentage_weight;

    animalName{iSubject} = subject;
    prcWeightToday{iSubject} = num2str(weightPrc, '%4.2f');
%     prcWeightToday(iSubject) = round(weightPrc(1)*1000)/10;
    for iDay = 1:nDaysInFuture
        doExclude = ismember(subject, fieldnames(exclude));
        if doExclude && any(floor([exclude.(subject)]) == floor(now+iDay))
            giveWater{iSubject, iDay} = 'PIL';
            waterValues{iSubject, iDay} = 'Skipped';
        else
            try
                iRecord = strcmp(datestr(now+iDay,'yyyy-mm-dd'),{records.date});
                gw = records(iRecord).given_water_total;
                assert(gw > 0)
                giveWater{iSubject, iDay} = num2str(gw, '%4.2f');
                waterValues{iSubject, iDay} = gw;
            catch
                iRecord = strcmp(datestr(now,'yyyy-mm-dd'),{records.date});
                gw = round(records(iRecord).expected_water, 2) + 0.05;
                giveWater{iSubject, iDay} = num2str(gw, '%4.2f');
                % post water here
                ai.postWater(subject, gw, now + iDay, 'Water');
                waterValues{iSubject, iDay} = gw;
                advancedPost(iSubject, iDay) = false;
            end
        end
    end
end
%%% FOR DEBUGGING %%%
save getWeekendWaterVars.mat
%%%
% collect the data for the table
data = table(animalName, prcWeightToday, giveWater);
