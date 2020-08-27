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
            % WW.PARAMS Loads the parameters for the weekend water script
            obj.load()
        end
        
        function set(obj, name, value)
            % SET Sets the value for a given parameter
            parameterNames = fieldnames(obj.Parameters);
            assert(ismember(name, parameterNames), ...
                'parameter not found, should be one of the following parameters:\n%s', ...
                strjoin(parameterNames, ', '))
            obj.Parameters.(name) = value;
        end
        
        function p = get(obj, name)
            % GET Returns the value for a given parameter
            parameterNames = fieldnames(obj.Parameters);
            assert(ismember(name, parameterNames), ...
                'parameter not found, should be one of the following parameters:\n%s', ...
                strjoin(parameterNames, ', '))
            p = obj.Parameters.(name);
        end
        
        function fields = list(obj)
            % LIST Lists the parameter fields
            fields = string(fieldnames(obj.defaults));
        end
        
        function TF = get.FileExists(obj)
            % FILEEXISTS True if the parameter file exists
            TF = file.exists(obj.path);
        end
        
        function when = get.LastUpdated(obj)
            % LASTUPDATED The modified date of the parameters file
            %   Returns a datestr of the time and date of when the
            %   parameters file was last modified, or 'Never' if the file
            %   has no such date
            modified = datestr(file.modDate(obj.path));
            when = iff(obj.FileExists, modified, 'Never');
        end
        
        function load(obj)
            % LOAD Loads the parameters from file
            params = iff(obj.FileExists, @() jsondecode(fileread(obj.path)), struct);
            obj.Parameters = mergeStruct(obj.defaults, params);
        end
        
        function save(obj)
            % SAVE Saves the parameters to file
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
               
    end
    
    methods (Access = private, Static)
        function p = defaults
            % DEFAULTS Returns the default parameter structure
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
                'CAL_API_URL', 'https://www.calendarific.com/api/v2/holidays', ...
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
            % PATH Return the full path to the parameters file
            basedir = iff(ispc, getenv('APPDATA'), getenv('HOME'));
            parspath = fullfile(basedir, '.weekend_water_pars.json');
        end
        
    end
end
