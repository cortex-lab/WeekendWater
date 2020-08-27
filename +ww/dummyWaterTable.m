function data = dummyWaterTable(~, nDaysInFuture, ~)
% ww.dummyWaterTable Simulates the output of ww.getWeekendWater
nSubjects = 10;
if nargin < 2; nDaysInFuture = 2; end
animalName = strcat('Mouse_', strsplit(num2str(1:nSubjects)));
prcWeightToday = mapToCell(@(~)num2str(80+rand, '%4.2f'), cell(nSubjects, 1));
giveWater = mapToCell(@(~)num2str(0.5+rand, '%4.2f'), cell(nSubjects, 1));
giveWater = repmat(giveWater,1,nDaysInFuture);

data = table(animalName(:), prcWeightToday, giveWater);