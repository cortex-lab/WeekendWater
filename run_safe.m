function status = run_safe
try    
    ww.generate;
    status = 0;
catch
    status = 1;
end