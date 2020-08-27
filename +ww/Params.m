classdef Params < handle
    
    properties (Dependent)
        FileExists logical
        LastUpdated char
    end
    
    properties (Access = private)
        Parameters struct
    end
    
    methods
        
        function obj = Params()
            obj.load()
        end
        
        function set(obj, name, value)
            parameterNames = fieldnames(obj.Parameters);
            assert(ismember(name, parameterNames), ...
                'parameter not found, should be one of the following parameters:\n%s', ...
                strjoin(parameterNames, ', '))
            obj.Parameters.(name) = value;
        end
        
        function p = get(obj, name)
            parameterNames = fieldnames(obj.Parameters);
            assert(ismember(name, parameterNames), ...
                'parameter not found, should be one of the following parameters:\n%s', ...
                strjoin(parameterNames, ', '))
            p = obj.Parameters.(name);
        end
        
        function TF = get.FileExists(obj)
            TF = file.exists(obj.path);
        end
        
        function when = get.LastUpdated(obj)
            modified = datestr(file.modDate(obj.path));
            when = iff(obj.FileExists, modified, 'Never');
        end
        
        function load(obj)
            params = iff(obj.FileExists, @() jsondecode(fileread(obj.path)), struct);
            obj.Parameters = mergeStruct(obj.defaults, params);
        end
        
        function save(obj)
            params = obj.Parameters;
            % Remove any params that are not in the default structure
            for f = setdiff(fieldnames(params), fieldnames(obj.defaults))'
                params = rmfield(params, f);
            end
            jsonStr = jsonencode(params);
            fid = fopen(obj.path, 'w');
            if fid == -1, error('Cannot create JSON file'), end
            fwrite(fid, jsonStr, 'char');
            fclose(fid);
        end
        
        function obj = setup(obj)
            % WW.PARAMS.SETUP Set or update the weekend water preferences
            %  Parameters are saved in AppData and contains the database settings and
            %  so forth
            
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
            
            % --------------------
            disp('Setting up email STMP server settings...')
            disp('...Press return to keep unchanged...')
            prompt = sprintf('SMTP server address: (%s)', obj.Parameters.SMTP_Server);
            reply = input(prompt,'s');
            if ~isempty(reply)
                obj.Parameters.SMTP_Server = reply;
            end
            prompt = sprintf('SMTP server port: (%i)', obj.Parameters.SMTP_Port);
            reply = input(prompt);
            if ~isempty(reply)
                if ischar(reply) || isstring(reply)
                    reply = str2double(reply);
                end
                obj.Parameters.SMTP_Port = reply;
            end
            prompt = sprintf('Account username: (%s)', obj.Parameters.SMTP_Username);
            reply = input(prompt,'s');
            if ~isempty(reply)
                obj.Parameters.SMTP_Username = reply;
            end
            prompt = sprintf('Account password: ');
            reply = input(prompt,'s');
            if ~isempty(reply)
                obj.Parameters.SMTP_Password = reply;
            end
            % --------------------
            disp('Alyx user account to use...')
            prompt = sprintf('Alyx username: (%s) ', obj.Parameters.ALYX_Login);
            reply = input(prompt,'s');
            if ~isempty(reply)
                obj.Parameters.ALYX_Login = reply;
            end
            prompt = sprintf('Alyx password: ');
            reply = input(prompt,'s');
            if ~isempty(reply)
                obj.Parameters.ALYX_Password = reply;
            end
            % --------------------
            disp('Setting up calandar API settings (for determining bank holidays)...')
            prompt = sprintf('API URL: (%s) ', obj.Parameters.CAL_API_URL);
            reply = input(prompt,'s');
            if ~isempty(reply)
                obj.Parameters.CAL_API_URL = reply;
            end
            prompt = sprintf('API key: (%s) ', obj.Parameters.CAL_API_KEY);
            reply = input(prompt,'s');
            if ~isempty(reply)
                obj.Parameters.CAL_API_KEY = reply;
            end
            prompt = sprintf('Country code: (%s) ', obj.Parameters.CAL_Country);
            reply = input(prompt,'s');
            if ~isempty(reply)
                obj.Parameters.CAL_Country = reply;
            end
            prompt = sprintf('Region: (%s) ', obj.Parameters.CAL_Region);
            reply = input(prompt,'s');
            if ~isempty(reply)
                obj.Parameters.CAL_Region = reply;
            end
            % --------------------
            disp('Setting up script preferences...')
            prompt = sprintf('Mode (0 = normal, 1 = debug, test = 2): (%i) ',...
                obj.Parameters.Mode);
            reply = input(prompt);
            if ~isempty(reply)
                assert(reply >= 0 && reply < 3)
                obj.Parameters.Mode = int8(reply);
            end
            prompt = sprintf('Number of days to post water for: (%i) ',...
                obj.Parameters.nDaysInFuture);
            reply = input(prompt);
            if ~isempty(reply)
                assert(reply > 0)
                obj.Parameters.nDaysInFuture = int8(reply);
            end
            % --------------------
            disp('Setting up email recipients...')
            disp('Please enter a single email in quotes, or a cell array of emails')
            prompt = sprintf('Email admin(s) (to recieve warnings, etc.): (%s) ',...
                strjoin(obj.Parameters.Email_admins, ', '));
            reply = input(prompt);
            if ~isempty(reply)
                obj.Parameters.Email_admins = ensureCell(reply);
            end
            prompt = sprintf('Email recipients(s) (to recieve water list): (%s) ',...
                strjoin(obj.Parameters.Email_recipients, ', '));
            reply = input(prompt);
            if ~isempty(reply)
                obj.Parameters.Email_recipients = ensureCell(reply);
            end
        end

        
    end
    
    methods (Access = private, Static)
        function p = defaults
            p = struct( ...
                ... Water email server settings ...
                'SMTP_Server', 'smtp.gmail.com', ...
                'SMTP_Port',  587, ...
                'SMTP_Username', '', ...
                'SMTP_Password', '', ...
                'E_mail', '', ...
                ... Alyx database settings ...
                'ALYX_URL',  'https://alyx.cortexlab.net', ...
                'ALYX_DEV_URL',  'https://alyx-dev.cortexlab.net', ...
                'ALYX_Login',  'wateruser', ...
                'ALYX_Password',  '', ...
                ... Bank holiday API ...
                'CAL_API_URL', 'https://www.calendarindex.com/api/v2/holidays', ...
                'CAL_API_KEY', '', ...
                'CAL_Country', 'GB', ...
                'CAL_Region', 'England', ...
                ... Preferences ...
                'Mode',  2, ...
                'nDaysInFuture', 2, ...
                'Email_format', 'html', ...
                'Email_admins', {''}, ...
                'Email_recipients', {''});
        end
        
        function parspath = path
            basedir = iff(ispc, getenv('APPDATA'), getenv('HOME'));
            parspath = fullfile(basedir, '.weekend_water_pars.json');
        end
        
    end
end
