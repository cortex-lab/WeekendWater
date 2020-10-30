function generate(nDays, varargin)
% GENERATE Create a list of subjects and dates to be trained on weekend
%
%  Inputs:
%    nDays: The number of day in the future to post water for.  If empty or
%           not defined, the 'nDaysInFuture' parameter is used (adjusted  
%           for bank holidays)
%
%  Named Parameters:
%    force: When true the script is run regardless of the 'minLastSent' 
%           parameter (default: false)
%    test: When true the script is run in test mode (default: false)
%
%  Examples:
%    % Run using standard defaults (2 days in future)
%    ww.generate
%
%    % Post water for 3 days in future, regardless of when it was last run
%    ww.generate(3, 'force', true)

% Ensure we're on the correct branch and up-to-date
git.runCmd({'checkout dev', 'pull'}, 'dir', getOr(dat.paths, 'rigbox'));

% Load the parameters
params = ww.Params;
admins = strip(lower(params.get('Email_admins')));

% Parse input arguments (override params)
p = inputParser;
p.addParameter('force', false, @islogical)
p.addParameter('test', params.get('Mode') == 2, @islogical)
p.parse(varargin{:})
force = p.Results.force;
test = p.Results.test;
debug = params.get('Mode') > 0 || test;
% Temp dir for saving log and email
tmpdir = iff(ispc, getenv('APPDATA'), getenv('HOME'));
if debug
    % In debug mode we activate the log
    diaryState = get(0, 'Diary');
    diaryFile = get(0, 'DiaryFile');
    diary(fullfile(tmpdir, 'ww.log'))
end

% Get list of mice to be trained over the weekend.  These will be marked as
% 'PIL' on the list (so long as they've been weighed)
excl = dat.loadParamProfiles('WeekendWater');
if isempty(fieldnames(excl)), excl = struct; end

% Path to email file which will be sent
filename = sprintf('mail%s.txt', iff(test, '-test', ''));
mail = fullfile(tmpdir, filename);

% Check when email was last generated and potentially return if too soon
mod = file.modDate(mail);
minLastSent = params.get('minLastSent'); % min number of days before next
if ~force && ~test && ~isempty(mod) && (now - mod < minLastSent)
    fprintf('Email already sent in last %.2g days\n', minLastSent)
    return
end

% Set email prefs for sending the email
% TODO These may no longer be required as we use curl
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.port', num2str(params.get('SMTP_Port')));
props.setProperty('mail.smtp.starttls.enable','true');
% We use MATLAB to send plain text warnings
internetPrefs = getpref('Internet');
for prop = string(fieldnames(internetPrefs))'
    setpref('Internet', prop, params.get(prop))
end

if nargin == 0 || isempty(nDays)
    % use 2 for usual weekends, 3 for long weekends etc.
    [nDays, fail] = ww.getNumDays();
    if fail && ~test
      sendmail(admins, 'Action required: Days may be incorrect',...
        ['Weekend water script failed to determine whether there are '...
         'any upcoming Bank holidays.  Investigate.']);
    end
end

% Alyx instance
ai = Alyx('','');
if test
  ai.BaseURL = params.get('ALYX_DEV_URL');
  fprintf('Using test database: %s\n', ai.BaseURL);
end
ai = ai.login(params.get('ALYX_Login'), params.get('ALYX_Password'));

% Table of users and their emails from database
users = ai.getData('users');

% Extract the data from alyx and give water to whomever needs it
[data, skipped] = ww.getWeekendWater(ai, nDays, excl);
if height(data) == 0, return, end  % Return if there are no restricted mice

if ~isempty(skipped) && ~test
    msg = sprintf(['The following mice have no weekend water information:\n\r %s\n\r',...
   'This occured because a weight for today was not inputted into Alyx before 6pm. \n',...
    'Please manually write the weight and water to be given on the paper sheet upstairs. ',...
    'For the days you will be training, please write ''PIL''.'], strjoin({skipped.subject}, '\n'));
    [~,I] = intersect({users.username}, {skipped.user});
    sendmail(vertcat(users(I).email, admins),...
      'Action required: Weekend information missing', msg);
end

% print nicely, 'water.png' will be saved in the current folder
data = ww.formatTable(data, params.get('Email_format'));

% Get list of email recipients
recipients = strip(lower(params.get('Email_recipients')));
% In test mode only send to admin, otherwise send to all recipients and admins
to = iff(test, admins(1), union(recipients, admins));

%%  'Weekend water',...
% Write email to file
fid = fopen(mail, 'w', 'n', 'UTF-8');
fprintf(fid, ['From: Alyx Database <%s>\n',...
    'Reply-To: Alyx Database <%s>\n',...
    'To: %s\nSubject: Weekend Water\n',...
    'Content-Type: text/html; charset="utf-8"\n',...
    'Content-Transfer-Encoding: quoted-printable\n',...
    'Mime-version: 1.0\n\n<!DOCTYPE html><html lang="en-GB"><head>',...
    '<title>Weekend Water Email</title>'...
    '</head><body>\n',...
    'Please find below the water table for this weekend.  ',...
    'Any blank spaces must be filled in manually by the respective ',...
    'PILs on the paper copy.  Let us know if they fail to do so. \n \r',...
    '%s\n</body></html>'],...
    getpref('Internet','E_mail'), getpref('Internet','E_mail'),...
    strjoin(to, ', '), data);
fclose(fid);

% Construct curl command
cmd = sprintf(['curl "%s:%i" -v --mail-from "%s" ',...
    '--mail-rcpt "%s" --ssl -u %s:%s -T "%s" -k --anyauth'],...
    params.get('SMTP_Server'), params.get('SMTP_Port'), params.get('E_mail'), ...
    strjoin(to, '" --mail-rcpt "'), getpref('Internet','E_mail'),...
    getpref('Internet','SMTP_Password'), strrep(mail, '\', '/'));

% Wrap in call to git bash
gitExe = getOr(dat.paths, 'gitExe');
bashPath = fullfile(gitExe(1:end-11), 'git-bash.exe');
bash = @(cmd)['"',bashPath,'" -c "',cmd,'"'];
failed = system(bash(cmd), '-echo'); % Send email

assert(~failed, 'failed to send email')

% Restore previous preferences
for prop = string(fieldnames(internetPrefs))'
    setpref('Internet', prop, internetPrefs.(prop))
end
% Restore diary state
if debug, diary(diaryState), set(0, 'DiaryFile', diaryFile), end