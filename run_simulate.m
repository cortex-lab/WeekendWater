function status = run_simulate
try    
    ww.simulate;
    status = 0;
catch e
    warning(e.identifier, 'ERROR: %s', e.message);
    status = 1;
end