function generate()
% GENERATE Create a list of subjects and dates to be trained on weekend
% 

% Ensure we're on the correct branch and up-to-date
git.runCmd({'checkout dev', 'pull'}, 'dir', getOr(dat.paths, 'rigbox'));

% Load the parameters
params = ww.Params;
test = params.get('Mode') == 2;
admins = strip(lower(params.get('Email_admins')));

% Get list of mice to be trained over the weekend.  These will be marked as
% 'PIL' on the list (so long as they've been weighed)
excl = dat.loadParamProfiles('WeekendWater');
if isempty(fieldnames(excl)), excl = struct; end

% Path to email file which will be sent
mail = fullfile(iff(ispc, getenv('APPDATA'), getenv('HOME')), 'mail.txt');
% mod = file.modDate(mail);
% Check if email was generated in the past 2 days
% if ~isempty(mod) && (now - file.modDate(which('dat.paths')) < 2)
%     return
% end

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

% use 2 for usual weekends, 3 for long weekends etc.
[nDays, fail] = getNumDays();
if fail && ~test
  sendmail(admins, 'Action required: Days may be incorrect',...
    ['Weekend water script failed to determine whether there are any upcoming ',...
    'Bank holidays.  Investigate']);
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
[data, skipped] = getWeekendWater(ai, nDays, excl);
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
data = printWeekendWater(data, params.get('Email_format'));

% Get list of email recipients
recipients = strip(lower(params.get('Email_recipients')));
% In test mode only send to admin, otherwise send to all recipients and admins
to = iff(test, admins{1}, union(recipients, admins));

%%  'Weekend water',...
% Write email to file
fid = fopen(mail, 'w');
fprintf(fid, ['From: Alyx Database <%s>\n',...
    'Reply-To: Alyx Database <%s>\n',...
    'To: %s\nSubject: Weekend Water\n',...
    'Content-Type: text/html; charset="us-ascii"\n',...
    'Content-Transfer-Encoding: quoted-printable\n',...
    'Mime-version: 1.0\n\n<html><head>',...
    '<meta http-equiv=3D"Content-Type" content=3D"text/html; charset=3Dus-ascii">\n',...
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
    strjoin(to, "' --mail-rcpt '"), getpref('Internet','E_mail'),...
    getpref('Internet','SMTP_Password'), strrep(mail, '\', '/'));

% Wrap in call to git bash
gitExe = getOr(dat.paths, 'gitExe');
bashPath = fullfile(gitExe(1:end-11), 'git-bash.exe');
bash = @(cmd)['"',bashPath,'" -c "',cmd,'"'];
system(bash(cmd), '-echo'); % Send email

% Restore previous preferences
for prop = string(fieldnames(internetPrefs))'
    setpref('Internet', prop, s.(prop))
end