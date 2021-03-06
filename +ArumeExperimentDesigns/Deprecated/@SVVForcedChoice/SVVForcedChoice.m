classdef SVVForcedChoice < ArumeExperimentDesigns.SVV2AFC
    %SVVdotsAdaptFixed Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        eyeTracker = [];
        
        lastResponse = '';
        reactionTime = '';
        
        fixColor = [255 0 0];
        
        targetColor = [255 0 0];
        
        currentAngle = 0;
        currentCenterRange = 0;
        currentRange = 180;
    end
    
    % ---------------------------------------------------------------------
    % Options to set at runtime
    % ---------------------------------------------------------------------
    methods ( Static = true )
        function dlg = GetOptionsStructDlg( this )
            dlg.UseGamePad = { {'0','{1}'} };
            dlg.UseLine = { {'0','{1}'} };
            dlg.FixationDiameter = { 12.5 '* (pix)' [3 50] };
            dlg.TargetDiameter = { 12.5 '* (pix)' [3 50] };
            dlg.targetDistance = { 300 '* (pix)' [10 500] };
            dlg.fixationDuration = { 1000 '* (ms)' [100 3000] };
            dlg.targetDuration = { 300 '* (ms)' [100 30000] };
            dlg.responseDuration = { 1500 '* (ms)' [100 3000] };
        end
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function initExperimentDesign( this  )
            
            this.trialDuration = this.ExperimentOptions.fixationDuration/1000 ...
                + this.ExperimentOptions.targetDuration/1000 ...
                + this.ExperimentOptions.responseDuration/1000 ; %seconds
            
            % default parameters of any experiment
            this.trialSequence      = 'Random';      % Sequential, Random, Random with repetition, ...
            this.trialAbortAction   = 'Delay';    % Repeat, Delay, Drop
            this.trialsPerSession   = 170;
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 5;
            this.blocksToRun = 1;
            this.blocks = [ struct( 'fromCondition', 1, 'toCondition', 34, 'trialsToRun', 34) ];
        end
        
        function initBeforeRunning( this )
            if ( this.ExperimentOptions.UseGamePad )
                ArumeHardware.GamePad.Open
            end
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Angle';
            conditionVars(i).values = [-16:2:16];
            
            i = i+1;
            conditionVars(i).name   = 'Position';
            conditionVars(i).values = {'Up' 'Down'};
        end
        
        function trialResult = runPreTrial(this, variables )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            % Add stuff here
            
            this.currentAngle = variables.Angle;
            
            trialResult =  Enum.trialResult.CORRECT;
        end
        
        function trialResult = runTrial( this, variables )
            
            try
                this.lastResponse = -1;
                this.reactionTime = -1;
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                
                graph = this.Graph;
                
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
                Screen('FillRect', graph.window, 0);
                lastFlipTime        = Screen('Flip', graph.window);
                secondsRemaining    = this.trialDuration;
                
                startLoopTime = lastFlipTime;
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - startLoopTime;
                    secondsRemaining    = this.trialDuration - secondsElapsed;
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    %-- Find the center of the screen
                    [mx, my] = RectCenter(graph.wRect);
                    
                    t1 = this.ExperimentOptions.fixationDuration/1000;
                    t2 = this.ExperimentOptions.fixationDuration/1000 +this.ExperimentOptions.targetDuration/1000;
                    
                    if (secondsElapsed < t2)
                        %-- Draw fixation spot
                        fixRect = [0 0 this.ExperimentOptions.FixationDiameter this.ExperimentOptions.FixationDiameter];
                        fixRect = CenterRectOnPointd( fixRect, mx, my );
                        Screen('FillOval', graph.window, this.fixColor, fixRect);
                    end
                    
                    if ( secondsElapsed > t1 && secondsElapsed < t2 )
                        switch(this.ExperimentOptions.UseLine )
                            case 0
                                %-- Draw target
                                targetRect = [0 0 this.ExperimentOptions.TargetDiameter this.ExperimentOptions.TargetDiameter];
                                
                                targetDist = this.ExperimentOptions.targetDistance;
                                switch(variables.Position)
                                    case 'Up'
                                        targetRect = CenterRectOnPointd( targetRect, mx + targetDist*sin(this.currentAngle/180*pi), my - targetDist*cos(this.currentAngle/180*pi) );
                                    case 'Down'
                                        targetRect = CenterRectOnPointd( targetRect, mx - targetDist*sin(this.currentAngle/180*pi), my + targetDist*cos(this.currentAngle/180*pi) );
                                end
                                Screen('FillOval', graph.window, this.targetColor, targetRect);
                            case 1
                                switch(variables.Position)
                                    case 'Up'
                                        fromH = mx;
                                        fromV = my;
                                        toH = mx + this.ExperimentOptions.targetDistance*sin(this.currentAngle/180*pi);
                                        toV = my - this.ExperimentOptions.targetDistance*cos(this.currentAngle/180*pi);
                                    case 'Down'
                                        fromH = mx;
                                        fromV = my;
                                        toH = mx - this.ExperimentOptions.targetDistance*sin(this.currentAngle/180*pi);
                                        toV = my + this.ExperimentOptions.targetDistance*cos(this.currentAngle/180*pi);
                                end
                                Screen('DrawLine', graph.window, this.targetColor, fromH, fromV, toH, toV, 4);
                        end
                    end
                    
                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------
                    
                    
                    % -----------------------------------------------------------------
                    % DEBUG
                    % -----------------------------------------------------------------
                    if (0)
                        % TODO: it would be nice to have some call back system here
                        Screen('DrawText', graph.window, sprintf('%i seconds remaining...', round(secondsRemaining)), 20, 50, graph.white);
                        currentline = 50 + 25;
                        vNames = fieldnames(variables);
                        for iVar = 1:length(vNames)
                            if ( ischar(variables.(vNames{iVar})) )
                                s = sprintf( '%s = %s',vNames{iVar},variables.(vNames{iVar}) );
                            else
                                s = sprintf( '%s = %s',vNames{iVar},num2str(variables.(vNames{iVar})) );
                            end
                            Screen('DrawText', graph.window, s, 20, currentline, graph.white);
                            
                            currentline = currentline + 25;
                        end
                    end
                    % -----------------------------------------------------------------
                    % END DEBUG
                    % -----------------------------------------------------------------
                    
                    
                    % -----------------------------------------------------------------
                    % -- Flip buffers to refresh screen -------------------------------
                    % -----------------------------------------------------------------
                    this.Graph.Flip();
                    % -----------------------------------------------------------------
                    
                    
                    % -----------------------------------------------------------------
                    % --- Collecting responses  ---------------------------------------
                    % -----------------------------------------------------------------
                    
                    if ( secondsElapsed > t1  )
                        
                        if ( this.ExperimentOptions.UseGamePad )
                            [d, l, r] = ArumeHardware.GamePad.Query;
                            if ( l == 1)
                                switch(variables.Position)
                                    case 'Up'
                                        this.lastResponse = 1;
                                    case 'Down'
                                        this.lastResponse = 0;
                                end
                            elseif( r == 1)
                                switch(variables.Position)
                                    case 'Up'
                                        this.lastResponse = 0;
                                    case 'Down'
                                        this.lastResponse = 1;
                                end
                            end
                        else
                            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                            if ( keyIsDown )
                                keys = find(keyCode);
                                for i=1:length(keys)
                                    KbName(keys(i))
                                    switch(KbName(keys(i)))
                                        case 'RightArrow'
                                            switch(variables.Position)
                                                case 'Up'
                                                    this.lastResponse = 1;
                                                case 'Down'
                                                    this.lastResponse = 0;
                                            end
                                        case 'LeftArrow'
                                            switch(variables.Position)
                                                case 'Up'
                                                    this.lastResponse = 0;
                                                case 'Down'
                                                    this.lastResponse = 1;
                                            end
                                    end
                                end
                            end
                        end
                    end
                    if ( this.lastResponse >= 0 )
                        this.reactionTime = secondsElapsed-1;
                        disp(num2str(this.lastResponse));
                        break;
                    end
                    
                    
                    % -----------------------------------------------------------------
                    % --- END Collecting responses  -----------------------------------
                    % -----------------------------------------------------------------
                    
                end
            catch ex
                %  this.eyeTracker.StopRecording();
                rethrow(ex)
            end
            
            
            if ( this.lastResponse < 0)
                trialResult =  Enum.trialResult.ABORT;
            end
            
            % this.eyeTracker.StopRecording();
            
        end
        
        function trialOutput = runPostTrial(this)
            trialOutput = [];
            trialOutput.Response = this.lastResponse;
            trialOutput.ReactionTime = this.reactionTime;
            trialOutput.Angle = this.currentAngle;
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        % Function that gets the angles of each trial with 0 meaning
        % upright, positive tilted CW and negative CCW.
        function angles = GetAngles( this )
            angles = this.Session.trialDataSet.Angle;
            responses = 1-this.Session.trialDataSet.Response;
            angles = angles(responses<2);
        end
        
        % Function that gets the left and right responses with 1 meaning
        % right and 0 meaning left.
        function responses = GetLeftRightResponses( this )
            responses = 1-this.Session.trialDataSet.Response;
            responses = responses(responses<2);
        end
        
        function plotResults = Plot_ExperimentTimeCourse(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];
            NtrialPerBlock = 10;
            %             figure
            %             set(gca,'nextplot','add')
            %             colors = jet(length(ds)/NtrialPerBlock);
            
            Nblocks = ceil(length(ds)/NtrialPerBlock/2)*2;
            
            %             for i=NtrialPerBlock:NtrialPerBlock:length(ds)
            %                 nplot = ceil(i/NtrialPerBlock);
            %                 subplot(ceil(length(colors)/2),2,mod(((nplot*2)-1+floor((nplot-1)/(Nblocks/2)))-1,Nblocks)+1,'nextplot','add')
            %                 modelspec = 'Response ~ Angle';
            %                 subds = ds(1:i,:);
            %                 subds((subds.Response==1 & subds.Angle<-50) | (subds.Response==0 & subds.Angle>50),:) = [];
            %
            %                 [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
            %
            %                 plot(a,p, 'color', colors(nplot,:),'linewidth',2);
            %                 xlabel('Angle (deg)');
            %                 ylabel('Percent answered right');
            %
            %                 [svvr svvidx] = min(abs( p-50));
            %                 line([a(svvidx),a(svvidx)], [0 100], 'color', colors(nplot,:),'linewidth',2);
            %                 set(gca,'xlim',[-20 20])
            %
            %                 allAngles = -90:90;
            %                 allResponses = nan(size(allAngles));
            %                 for ia=1:length(allAngles)
            %                     allResponses(ia) = mean(responses(angles==allAngles(ia))*100);
            %                 end
            %
            %                 plot( allAngles,allResponses,'o')
            %                 text(3, 40, sprintf('SVV: %0.2f',a(svvidx)));
            %             end
            
            figure('position',[400 200 700 400],'color','w','name',this.Session.name)
            axes('nextplot','add');
            plot(ds(ds.Response==0 & strcmp(ds.Position,'Up'),'TrialNumber'), ds(ds.Response==0 & strcmp(ds.Position,'Up'),'Angle'),'^','MarkerEdgeColor',[0.3 0.3 0.3],'linewidth',2);
            plot(ds(ds.Response==1 & strcmp(ds.Position,'Up'),'TrialNumber'), ds(ds.Response==1 & strcmp(ds.Position,'Up'),'Angle'),'^','MarkerEdgeColor','r','linewidth',2);
            plot(ds(ds.Response==0 & strcmp(ds.Position,'Down'),'TrialNumber'), ds(ds.Response==0 & strcmp(ds.Position,'Down'),'Angle'),'v','MarkerEdgeColor',[0.3 0.3 0.3],'linewidth',2);
            plot(ds(ds.Response==1 & strcmp(ds.Position,'Down'),'TrialNumber'), ds(ds.Response==1 & strcmp(ds.Position,'Down'),'Angle'),'v','MarkerEdgeColor','r','linewidth',2);
            
            legend({'Answered tilted to the right', 'Answered tilted to the left'},'fontsize',16)
            legend('boxoff')
            set(gca,'xlim',[-3 103],'ylim',[-90 90])
            ylabel('Angle (deg)', 'fontsize',16);
            xlabel('Trial number', 'fontsize',16);
            set(gca,'ygrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
        end
        
        function plotResults = Plot_SigmoidUpDown(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];
            
            figure('position',[400 100 1000 600],'color','w','name',this.Session.name)
            subds = ds(strcmp(ds.Position,'Up'),:);
            subds((subds.Response==0 & subds.Angle<-50) | (subds.Response==1 & subds.Angle>50),:) = [];
            
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
            
            subplot(6,1,[1:2],'nextplot','add', 'fontsize',12);
            plot( allAngles, allResponses,'o', 'color', [0.7 0.7 0.7], 'markersize',10,'linewidth',2)
            plot(a,p, 'color', 'k','linewidth',2);
            line([SVV,SVV], [0 100], 'color','k','linewidth',2);
            
            
            %xlabel('Angle (deg)', 'fontsize',16);
            ylabel({'Percent answered' 'tilted right'}, 'fontsize',16);
            text(20, 80, sprintf('SVV: %0.2f�',SVV), 'fontsize',16);
            
            set(gca,'xlim',[-30 30],'ylim',[-10 110])
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca,'xticklabel',[])
            
            
            subplot(6,1,[3],'nextplot','add', 'fontsize',12);
            bar(allAngles, trialCounts, 'edgecolor','none','facecolor',[0.5 0.5 0.5])
            
            set(gca,'xlim',[-30 30],'ylim',[0 15])
            xlabel('Angle (deg)', 'fontsize',16);
            ylabel('Number of trials', 'fontsize',16);
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca, 'YAxisLocation','right')
            
            
            
            subds = ds(strcmp(ds.Position,'Down'),:);
            subds((subds.Response==0 & subds.Angle<-50) | (subds.Response==1 & subds.Angle>50),:) = [];
            
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
            
            subplot(6,1,[4:5],'nextplot','add', 'fontsize',12);
            plot( allAngles, allResponses,'o', 'color', [0.7 0.7 0.7], 'markersize',10,'linewidth',2)
            plot(a,p, 'color', 'k','linewidth',2);
            line([SVV, SVV], [0 100], 'color','k','linewidth',2);
            
            %xlabel('Angle (deg)', 'fontsize',16);
            ylabel({'Percent answered' 'tilted right'}, 'fontsize',16);
            text(20, 80, sprintf('SVV: %0.2f�',SVV), 'fontsize',16);
            
            set(gca,'xlim',[-30 30],'ylim',[-10 110])
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca,'xticklabel',[])
            
            
            subplot(6,1,[6],'nextplot','add', 'fontsize',12);
            bar(allAngles, trialCounts, 'edgecolor','none','facecolor',[0.5 0.5 0.5])
            
            set(gca,'xlim',[-30 30],'ylim',[0 15])
            xlabel('Angle (deg)', 'fontsize',16);
            ylabel('Number of trials', 'fontsize',16);
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca, 'YAxisLocation','right')
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
end

