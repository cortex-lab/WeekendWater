function setup
% WW.SETUP Set or update all the weekend water settings
%  Performs some simple requirements checks then prompts the user to
%  provide settings and preferences.

% Check for requirements % FIXME Move checks
assert(~verLessThan('matlab', '9.5'), 'Requires MATLAB 2018b or later')
assert(~isempty(which('dat.paths')), ...
    'Requires <a href="matlab:web(''%s'',''-browser'')">Rigbox</a>', ...
    'https://github.com/cortex-lab/Rigbox')
assert(~isempty(which('dat.paths')), ...
    'Requires <a href="matlab:web(''%s'',''-browser'')">Rigbox</a>', ...
    'https://github.com/cortex-lab/Rigbox')
gitExe = getOr(dat.paths, 'gitExe', '');
assert(file.exists(gitExe), ...
    ['Requires <a href="matlab:web(''%s'',''-browser'')">Git Bash</a>, '...
    'please ensure the ''gitExe'' field is updated in your paths file'],...
    'https://gitforwindows.org/')

params = ww.Params;
% ----STMP-SERVER-----
disp('Setting up email STMP server settings...')
disp('...Press return to keep unchanged...')
prompt = sprintf('SMTP server address: (%s)', params.get('SMTP_Server'));
reply = input(prompt,'s');
if ~isempty(reply)
    params.set('SMTP_Server') = reply;
end
prompt = sprintf('SMTP server port: (%i)', params.get('SMTP_Port'));
reply = input(prompt);
if ~isempty(reply)
    if ischar(reply) || isstring(reply), reply = str2double(reply); end
    params.set('SMTP_Port', reply);
end
prompt = sprintf('Account username: (%s)', params.get('SMTP_Username'));
reply = input(prompt,'s');
if ~isempty(reply), params.set('SMTP_Username', reply); end
fprintf('Account password: \n');
reply = passwordUI();
if ~isempty(reply), params.set('SMTP_Password', reply); end
% --------ALYX--------
disp('Alyx user account to use...')
prompt = sprintf('Alyx username: (%s) ', params.get('ALYX_Login'));
reply = input(prompt,'s');
if ~isempty(reply), params.set('ALYX_Login', reply); end
fprintf('Alyx password: \n');
reply = passwordUI();
if ~isempty(reply), params.set('ALYX_Password', reply); end
% ------CALENDAR------
disp('Setting up calandar API settings (for determining bank holidays)...')
prompt = sprintf('API URL: (%s) ', params.get('CAL_API_URL'));
reply = input(prompt,'s');
if ~isempty(reply), params.set('CAL_API_URL', reply); end
prompt = sprintf('API key: (%s) ', params.get('CAL_API_KEY'));
reply = input(prompt,'s');
if ~isempty(reply), params.set('CAL_API_KEY', reply); end
prompt = sprintf('Country code: (%s) ', params.get('CAL_Country'));
reply = input(prompt,'s');
if ~isempty(reply), params.set('CAL_Country', reply); end
prompt = sprintf('Region: (%s) ', params.get('CAL_Region'));
reply = input(prompt,'s');
if ~isempty(reply), params.set('CAL_Region', reply); end
% -----PREFERENCES-----
disp('Setting up script preferences...')
prompt = sprintf('Mode (0 = normal, 1 = debug, test = 2): (%i) ',...
    params.get('Mode'));
reply = input(prompt);
if ~isempty(reply)
    assert(reply >= 0 && reply < 3)
    params.set('Mode', int8(reply));
end
prompt = sprintf('Number of days to post water for: (%i) ',...
    params.get('nDaysInFuture'));
reply = input(prompt);
if ~isempty(reply)
    assert(reply > 0)
    params.set('nDaysInFuture', int8(reply));
end
% -----EMAILS------
disp('Setting up email recipients...')
disp('Please enter a single email in quotes, or a cell array of emails')
prompt = sprintf('Email admin(s) (to recieve warnings, etc.): (%s) ',...
    strjoin(params.get('Email_admins'), ', '));
reply = input(prompt);
if ~isempty(reply)
    params.set('Email_admins', ensureCell(reply));
end
prompt = sprintf('Email recipients(s) (to recieve water list): (%s) ',...
    strjoin(params.get('Email_recipients'), ', '));
reply = input(prompt);
if ~isempty(reply)
    params.set('Email_recipients', ensureCell(reply));
end

params.save
disp('Parameters saved')