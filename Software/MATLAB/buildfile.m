function plan = buildfile
    %% Start creating tasks
    plan = buildplan;
    
    %% Add a clean task
    plan("clean") = matlab.buildtool.tasks.CleanTask();

    %% Add a test task
    plan("test") = matlab.buildtool.tasks.TestTask("TestResults","results.xml");
        
    
