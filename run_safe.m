function status = run_safe
try    
    ww.generate;
    status = 0;
catch e
    warning(e.identifier, 'ERROR: %s', e.message);
    status = 1;
end