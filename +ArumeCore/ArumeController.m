classdef ArumeController < handle
    % ARUME Is a GUI to control experiments and analyze their results.
    %
    %   Usage   : Arume, opens Arume GUI.
    %           : Arume( 'open', 'C:\path\to\project.aprj' ), opens a given project
    %
    % A project in Arume consists on multiple experimental SESSIONS and the
    % results ana analyses associted with them.
    %
    % A session is asociated with a given experimental paradigm selected
    % when the session is created.
    %
    % A session can be restarted, paused and resumed. Every time a new
    % experiment run is created containing the data related to each run.
    % That is, if you run the experiment, almost finish and the restart
    % over. All the data will be saved. For the first partial run and for
    % the second complete run.
    %
    % A project can have sessions of different paradigms but a session will
    % have runs of one individual paradigm.
    %
    % The projects can be managed with the GUI but also with command line. 
    
    properties( Constant=true )
        AnalysisMethodPrefix = 'Analysis_';
        PlotsMethodPrefix = 'Plot_';
        PlotsAggregateMethodPrefix = 'PlotAggregate_';
    end
    
    properties( Access=private )
        configuration       % Configuration options saved into a mat file in the Arume folder
    end
    
    properties
        gui                 % Current gui associated with the controller
        possibleExperiments % List of possible experiments
    end
    
    properties( SetAccess=private )
        currentProject      % Current working project 
        selectedSessions    % Current selected sessions (if multiple selected enabled)
    end
        
    properties(Dependent=true)
        currentSession      % Current selected session (empty if none)
        
        defaultDataFolder   % Default data folder for new projects
        recentProjects      % List of recent projects
    end
    
    methods
        function session = get.currentSession( this )
            if ( length(this.selectedSessions) >= 1 )
                session = this.selectedSessions(end);
            else
                session = [];
            end
        end
        
        function defaultDataFolder = get.defaultDataFolder( this )
            if (~isempty(this.configuration) && isfield( this.configuration, 'defaultDataFolder' ) )
                defaultDataFolder = this.configuration.defaultDataFolder;
            else
                defaultDataFolder = '';
            end
        end
        
        function recentProjects = get.recentProjects( this )
            if (~isempty(this.configuration) && isfield( this.configuration, 'recentProjects' ) )
                recentProjects = this.configuration.recentProjects;
            else
                recentProjects = '';
            end
        end
        
    end
    
    methods( Access=public )
        
        %
        % Main constructor
        %
        
        function arumeController = ArumeController()
        end
        
        function init( this)
            % find the folder of arume
            [folder, name, ext] = fileparts(which('Arume'));
            
            % find the configuration file
            if ( ~exist(fullfile(folder,'arumeconf.mat'),'file'))
                conf = [];
                this.configuration = conf;
                save(fullfile(folder,'arumeconf.mat'), 'conf'); 
            end
            confdata = load(fullfile(folder,'arumeconf.mat'));
            conf = confdata.conf;
            
            % double check configuration fields
            if ( ~isfield( conf, 'defaultDataFolder') )
                conf.defaultDataFolder = fullfile(folder, 'ArumeData');
            end
            
            if ( ~isfield( conf, 'tempFolder') )
                conf.tempFolder = fullfile(folder, 'Temp');
            end

            % save the updated configuration
            this.configuration = conf;
            save(fullfile(folder,'arumeconf.mat'), 'conf'); 
            
            % create folders if they don't exist
            if ( ~exist( this.configuration.defaultDataFolder, 'dir') )
                mkdir(folder, 'ArumeData');
            end
            
            if ( ~exist( this.configuration.tempFolder, 'dir') )
                mkdir(folder, 'Temp');
            end
            
            % Get the list of possible experiments
            this.possibleExperiments = sort(ArumeCore.ExperimentDesign.GetExperimentList());
        end
        
        %
        % Managing projects
        %
        
        function newProject( this, parentPath, projectName, defaultExperiment )
            % Creates a new project
            
            this.currentProject = ArumeCore.Project.NewProject( parentPath, projectName, defaultExperiment);
            this.selectedSessions = [];
            
            this.updateRecentProjects(this.currentProject.path);
        end
        
        function loadProject( this, folder )  
            % Loads a project from a project folder
            
            if ( ~exist( folder, 'dir') )
                msgbox( 'The project folder does not exist.');
            end
            
            if ( ~isempty(this.currentProject) && strcmp(this.currentProject.path, folder))
                disp('Loading the same project folder that is currently loaded');
                return;
            end
            
            this.currentProject = ArumeCore.Project.LoadProject( folder );
            if ~isempty(this.currentProject.sessions) 
                this.selectedSessions = this.currentProject.sessions(1);
            else
                this.selectedSessions = [];
            end            
            
            this.updateRecentProjects(this.currentProject.path)
        end
        
        function loadProjectBackup( this, file, parentPath )  
            % Loads a project from a project file
            if ( ~exist( file, 'file') )
                msgbox( 'The project file does not exist.');
            end
            
            [~,projectName] = fileparts(file);
            
            if ( ~isempty(this.currentProject) && strcmp(this.currentProject.name, projectName))
                disp('Loading the same project file that is currently loaded');
                return;
            end
            
            this.currentProject = ArumeCore.Project.LoadProjectBackup( file, parentPath );
            if ~isempty(this.currentProject.sessions)
                this.selectedSessions = this.currentProject.sessions(1);
            else
                this.selectedSessions = [];
            end
            
            this.updateRecentProjects(this.currentProject.path)
        end
        
        function saveProjectBackup(this, file)
            if ( exist( file, 'file') )
                msgbox( 'The file already exists.');
            end
            
            this.currentProject.backup(file);
        end

        function updateRecentProjects(this, currentProjectFile)
            
            if ( ~isfield(this.configuration, 'recentProjects' ) )
                this.configuration.recentProjects = {};
            end
            
            % remove the current file
            this.configuration.recentProjects = unique(this.configuration.recentProjects);
            if (~isempty( this.configuration.recentProjects ) )
                this.configuration.recentProjects =  this.configuration.recentProjects(1:min(30,length(this.configuration.recentProjects)));
            end
            this.configuration.recentProjects(find(strcmp(this.configuration.recentProjects, currentProjectFile))) = [];
            % add it again at the top
            this.configuration.recentProjects = [currentProjectFile this.configuration.recentProjects];
            conf = this.configuration;
            [folder, name, ext] = fileparts(which('Arume'));
            save(fullfile(folder,'arumeconf.mat'), 'conf'); 
        end
        
        function closeProject( this )
            % Closes the current project (always saves)
            
            this.currentProject.save();
            this.currentProject = [];
            this.selectedSessions = [];
        end
                
        %
        % Managing sessions
        %
        
        function setCurrentSession( this, currentSelection )
            % Updates the current session selection
            
            if  ~isempty( currentSelection )
                this.selectedSessions = this.currentProject.sessions(currentSelection);
            else
                this.selectedSessions = [];
            end
        end
        
        function session = newSession( this, experiment, subjectCode, sessionCode, experimentOptions )
            % Crates a new session to start the experiment and collect data
            
            % check if session already exists with that subjectCode and
            % sessionCode
            for session = this.currentProject.sessions
                if ( isequal(subjectCode, session.subjectCode) && isequal( sessionCode, session.sessionCode) )
                    error( 'Arume: session already exists use a diferent name' );
                end
            end
            
            session = ArumeCore.Session.NewSession( this.currentProject.path, experiment, subjectCode, sessionCode, experimentOptions );
            this.currentProject.addSession(session);
            this.selectedSessions = session;
            this.currentProject.save();
        end
        
        function session = importSession( this, experiment, subject_Code, session_Code, options )
            % Imports a session from external files containing the data. It
            % will not be possible to run this session
            
            % check if session already exists with that subjectCode and
            % sessionCode
            for session = this.currentProject.sessions
                if ( isequal(subject_Code, session.subjectCode) && isequal( session_Code, session.sessionCode) )
                    error( 'Arume: session already exists use a diferent name' );
                end
            end
            
            session = ArumeCore.Session.NewSession( this.currentProject.path, experiment, subject_Code, session_Code, options );
            this.currentProject.addSession(session);
            this.selectedSessions = session;
            
            session.importSession();
            
            this.currentProject.save();
        end
        
        function updateExperimentOptions( this, experiment, subject_Code, session_Code, options )
            session = this.currentProject.findSession( experiment, subject_Code, session_Code);
            session.experiment.UpdateExperimentOptions(options);
        end
        
        function renameSession( this, session, subjectCode, sessionCode)
            % Renames the current session
            
            for session1 = this.currentProject.sessions
                if ( isequal(subjectCode, session1.subjectCode) && isequal( sessionCode, session1.sessionCode) )
                    error( 'Arume: session already exists use a diferent name' );
                end
            end
            disp(['Renaming session' session.subjectCode ' - ' session.sessionCode ' to '  subjectCode ' - ' sessionCode]);
            
            [~, i] = this.currentProject.findSession(session.experiment.Name, session.subjectCode, session.sessionCode);
            this.currentProject.sessions(i).rename(subjectCode, sessionCode);
            this.currentProject.save();
        end
        
        function copySelectedSessions( this, newSubjectCodes, newSessionCodes)
            
            for i =1:length(this.selectedSessions)
                ArumeCore.Session.CopySession( this.selectedSessions(i), newSubjectCodes{i}, newSessionCodes{i});
            end
                        
            this.currentProject.save();
        end
        
        function deleteSelectedSessions( this )
            % Deletes the current session
            sessions = this.selectedSessions;
            
            for i =1:length(sessions)
                this.currentProject.deleteSession(sessions(i));
            end
            
            this.selectedSessions = [];
            
            this.currentProject.save();
        end
        
        %
        % Running sessions
        %
        
        function runSession( this )
            % Start running the experimental session
            
            this.currentSession.start();
            this.currentProject.save();
        end
        
        function resumeSession( this )
            % Resumes running the experimental session
            
            this.currentSession.resume();
            this.currentProject.save(); 
        end
        
        function restartSession( this )
            % Restarts a session from the begining. Past data will be saved.
            
            this.currentSession.restart();
            this.currentProject.save();
        end
         
        %
        % Analyzing and plotting
        %
        function prepareAnalysis( this, sessions )
            % Prepares the session for analysis. Mainly this creates the
            % trial dataset and the samples dataset
            
            useWaitBar = 0;
                       
            if ( ~exist('sessions','var') )
                sessions = this.selectedSessions;
                useWaitBar = 1;
            end
            
            n = length(sessions);
            
            if (useWaitBar)
                h = waitbar(0,'Please wait...');
            end
            
            for i =1:n
                try
                    disp(['ARUME::preparing analysis for session ' sessions(i).name])
                    session = sessions(i);
                    session.prepareForAnalysis();
                    if ( useWaitBar )
                        waitbar(i/n,h)
                    end
                catch ex
                    disp('Error preparing a session**************************');
                    ex.getReport()
                    disp('end Error preparing a session**************************');
                end
            end
            
            this.currentProject.save();
            
            if (useWaitBar)
                close(h);
            end
        end
                        
        function plotList = GetPlotList( this )
            plotList = {};
            methodList = meta.class.fromName(class(this.currentSession.experiment)).MethodList;
            for i=1:length(methodList)
                if ( strfind( methodList(i).Name, this.PlotsMethodPrefix) )
                    plotList{end+1} = strrep(methodList(i).Name, this.PlotsMethodPrefix ,'');
                end
            end
        end
        
        function plotList = GetAggregatePlotList( this )
            plotList = {};
            methodList = meta.class.fromName(class(this.currentSession.experiment)).MethodList;
            for i=1:length(methodList)
                if ( strfind( methodList(i).Name, this.PlotsAggregateMethodPrefix) )
                    plotList{end+1} = strrep(methodList(i).Name, this.PlotsAggregateMethodPrefix ,'');
                end
            end
        end
        
        function generatePlots( this, plots, selection, COMBINE_SESSIONS)
            if ( ~exist('COMBINE_SESSIONS','var' ) )
                COMBINE_SESSIONS = 0;
            end
             
            if ( ~isempty( selection ) )
                for i=1:length(selection)
                    if ( ismethod( this.currentSession.experiment, [this.PlotsMethodPrefix plots{selection(i)}] ) )
                        if ( ~COMBINE_SESSIONS)
                            % Single sessions plot
                            for session = this.selectedSessions
                                session.experiment.([this.PlotsMethodPrefix plots{selection(i)}])();
                            end
                        else 
                            
                            nplot1 = [1 2 1 2 2 2 2 2 3 2 4 4 4 4 4 4 5 5 5 5 5 5 5 5 5];
                            nplot2 = [1 1 3 2 3 3 4 4 3 5 3 3 4 4 4 4 4 4 4 4 5 5 5 5 5];
                            combinedFigures = [];
                            nSessions = length(this.selectedSessions);
                            p1 = nplot1(nSessions);
                            p2 = nplot2(nSessions);
                            iSession = 0;

                            % Single sessions plot
                            for session = this.selectedSessions
                                iSession = iSession+1;
                                handles = get(0,'children');
                                session.experiment.([this.PlotsMethodPrefix plots{selection(i)}])();

                                newhandles = get(0,'children');
                                for iplot =1:(length(newhandles)-length(handles))

                                    if ( length(combinedFigures) < i )
                                        combinedFigures(iplot) = figure;
                                    end

                                    idx = length(handles)+1;
                                    axorig = get(newhandles(1),'children');
                                    theTitle = strrep(get(newhandles(1),'name'),'_',' ');
                                    if ( iSession > 1 )
                                        axcopy = copyobj(axorig(end), combinedFigures(iplot));
                                    else
                                        % copy all including legend
                                        axcopy = copyobj(axorig(:), combinedFigures(iplot));
                                    end
                                    ax = subplot(p1,p2,iSession,axcopy(end));
                                    title(ax,theTitle);
                                end

                                close(setdiff( newhandles,handles))
                            end
                        end
                        
                    elseif ( ismethod( this.currentSession.experiment, [this.PlotsAggregateMethodPrefix plots{selection(i)}] ) )
                        % Aggregate session plots
                        this.currentSession.experiment.([this.PlotsAggregateMethodPrefix plots{selection(i)}])( this.selectedSessions );
                    end
                end
            end
        end
        
    end
    
end

