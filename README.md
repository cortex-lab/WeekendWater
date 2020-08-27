# WeekendWater
A script to post weekend water to Alyx and email users.

## Introduction
The script makes it easy to automatically post water amounts to the Alyx database for weekends and holidays.  In addition it sends an email to users with the required water for each day.  We use this to notify BSU staff of which subjects require water during weekends.

## Requirments
This is designed to work with Rigbox and Alyx.

1. [MATLAB](https://www.mathworks.com/products/matlab.html) 2018b or later
2. An instance of the [Alyx database](https://github.com/cortex-lab/alyx#alyx)
3. An STMP email account (e.g. GMail, Outlook)
4. [Rigbox](https://github.com/cortex-lab/Rigbox) v2.4 or later
5. [Git Bash](https://git-scm.com/download/win) (uses curl to send emails)
6. (Optional) An API key for [Calendarific](https://calendarific.com/api-documentation) to determine bank holidays

## Installing

1. Ensure the above requirements are installed.  For Rigbox, simply clone and run `addRigboxPaths` in MATAB.
2. In MATLAB, add the WeekendWater repository to your paths (e.g. `addpath('WeekendWater')`)
3. Follow [these instructions](http://cortex-lab.github.io/Rigbox/paths_config.html) on how to set up your Rigbox paths file.  You will need to ensure that the `gitExe` field points to your installed Git Bash executable, and the `mainRepository` is where your parameterProfiles.mat file will be saved (where subjects marked for weekend training are stored).
4. In MATLAB, run `ww.setup` and follow the steps to set the required parameters.
5. To run the script, say, every Friday, create a task on [Windows Scheduler](https://windowsreport.com/schedule-tasks-windows-10/).  Add an action to start a program.  The program should be MATLAB (i.e. `"C:\Program Files\MATLAB\R2018b\bin\matlab.exe"`) and the arguments should be `-r "ww.generate;exit"`.

## Updating parameters
Parameters can be updated using the `ww.Params` class, or by simply re-running `ww.setup`.  Below shows how to change the number of future weekend days to 3:
```
params = ww.Params;
params.set('nFutureDays', 3)
params.save
```

## Authors & Accreditation
The code was written by Miles Wells and Micheal Krumin.
