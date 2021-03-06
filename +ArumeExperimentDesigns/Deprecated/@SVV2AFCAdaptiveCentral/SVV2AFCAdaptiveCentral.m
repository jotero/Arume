classdef SVV2AFCAdaptiveCentral < ArumeExperimentDesigns.SVV2AFCAdaptive
    %SVVdotsAdaptFixed Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function dlg = GetOptionsDialog( this )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.SVV2AFC(this);
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
                    
                    lineLength = 300;
                                            
%                     if ( secondsElapsed > t1 && secondsElapsed < t2 )
                    if ( secondsElapsed > t1)
                        %-- Draw target
                        
                        angle = this.currentAngle;
                        position = variables.Position;
                                                
                                fromH = mx + lineLength*sin(angle/180*pi);
                                fromV = my - lineLength*cos(angle/180*pi);
                                
                                toH = mx - lineLength*sin(angle/180*pi);
                                toV = my + lineLength*cos(angle/180*pi);
                        
                        Screen('DrawLine', graph.window, this.targetColor, fromH, fromV, toH, toV, 4);
                       
                    end
                    
%                     if (secondsElapsed < t2)
%                         % black patch to block part of the line
                        
                        fixRect = [0 0 10 10];
                        fixRect = CenterRectOnPointd( fixRect, mx, my );
                        Screen('FillOval', graph.window,  this.targetColor, fixRect);
%                     end
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
                    
                    if ( secondsElapsed > max(t1,0.200)  )
                        response = this.CollectLeftRightResponse(0);
                        if ( ~isempty( response) )
                            this.lastResponse = response;
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
                rethrow(ex)
            end
            
            
            if ( this.lastResponse < 0)
                trialResult =  Enum.trialResult.ABORT;
            end
            
        end
        
        function trialOutput = runPostTrial(this)
            
            trialOutput = [];
            trialOutput.Response = this.lastResponse;
            trialOutput.ReactionTime = this.reactionTime;
            trialOutput.Angle = this.currentAngle;
            trialOutput.Range = this.currentRange;
            trialOutput.RangeCenter = this.currentCenterRange;
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
                
        function plotResults = Plot_ExperimentTimeCourse(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds.Response = ds.Response == 'L';
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
            
            
            SVV = nan(1,500);
            
            for i=1:50
                idx = (1:10) + (i-1)*10;
                ang = ds.Angle(idx);
                res = ds.Response(idx);
                
                [SVV1, a, p, allAngles, allResponses,trialCounts, SVVth1] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( ang, res);
                SVV(idx) = SVV1;
            end
            
            plot(SVV,'linewidth',2,'color',[.5 .8 .3]);
            
            legend({'Answered tilted to the right', 'Answered tilted to the left'},'fontsize',16)
            legend('boxoff')
            set(gca,'xlim',[-3 603],'ylim',[-90 90])
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
        
        function plotResults = Plot_ReactionTimes(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];
            
            angles = ds.Angle;
            times = ds.ReactionTime;
            
            binAngles = [-90:5:90];
            
            binMiddles = binAngles(1:end-1) + diff(binAngles)/2;
            timeAvg = zeros(size(binMiddles));
            for i=1:length(binMiddles)
                timeAvg(i) = median(times(angles>binAngles(i) & angles<binAngles(i+1)));
            end
            
            figure('position',[400 400 1000 400],'color','w','name',this.Session.name)
            axes( 'fontsize',12);
            plot(angles,times*1000,'o', 'color', [0.7 0.7 0.7], 'markersize',10,'linewidth',2)
            hold
            plot(binMiddles, timeAvg*1000, 'color', 'k','linewidth',2);
            set(gca,'xlim',[-30 30],'ylim',[0 1500])
            xlabel('Angle (deg)','fontsize',16);
            ylabel('Reaction time (ms)','fontsize',16);
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca,'xgrid','on')
            
            %%
        end
        
        function plotResults = PlotAggregate_SVVCombined(this, sessions)
            
            SVV = nan(size(sessions));
            SVVUp = nan(size(sessions));
            SVVDown = nan(size(sessions));
            SVVLine = nan(size(sessions));
            names = {};
            for i=1:length(sessions)
                session = sessions(i);
                names{i} = session.sessionCode;
                switch(class(session.experiment))
                    case {'ArumeExperimentDesigns.SVVdotsAdaptFixed' 'ArumeExperimentDesigns.SVVLineAdaptFixed' 'ArumeExperimentDesigns.SVVForcedChoice'}
                        ds = session.trialDataSet;
                        ds(ds.TrialResult>0,:) = [];
                        ds(ds.Response<0,:) = [];
                        
                        subds = ds(:,:);
                        [SVV(i), a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
                        
                        subds = ds(strcmp(ds.Position,'Up'),:);
                        [SVVUp(i), a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
                        subds = ds(strcmp(ds.Position,'Down'),:);
                        [SVVDown(i), a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
                        
                        
                    case 'ArumeExperimentDesigns.SVVClassical'
                        ds = session.trialDataSet;
                        ds(ds.TrialResult>0,:) = [];
                        
                        SVV(i) = median(ds.Response');
                        SVVLine(i) = SVV(i);
                    case {'ArumeExperimentDesigns.SVVClassicalUpDown' 'ArumeExperimentDesigns.SVVClassicalDotUpDown'}
                        ds = session.trialDataSet;
                        ds(ds.TrialResult>0,:) = [];
                        
                        SVV(i) = median(ds.Response');
                        SVVLine(i) = SVV(i);
                        
                        SVVUp(i) = median(ds.Response(streq(ds.Position,'Up'),:)');
                        SVVDown(i) = median(ds.Response(streq(ds.Position,'Down'),:)');
                end
            end
            
            figure('position',[100 100 1000 700])
            
            subplot(1,2,1,'fontsize',14);
            plot(SVV,1:length(SVV),'o','markersize',10)
            hold
            plot(SVVLine,1:length(SVV),'+','markersize',10)
            set(gca,'ytick',1:length(SVV),'yticklabel',names)
            
            set(gca,'ydir','reverse');
            line([0 0], get(gca,'ylim'),'color',[0.5 0.5 0.5])
            
            set(gca,'xlim',[-20 20])
            
            xlabel('SVV (deg)','fontsize',16);
            
            subplot(1,2,2,'fontsize',14);
            plot(SVVUp-SVVDown,1:length(SVV),'o','markersize',10)
            set(gca,'ytick',1:length(SVV),'yticklabel',names)
            set(gca,'ydir','reverse');
            line([0 0], get(gca,'ylim'),'color',[0.5 0.5 0.5])
            
            xlabel('SVV UP-Down diff. (deg)','fontsize',16);
            
            set(gca,'xlim',[-6 6])
            
            ds =[];
            
            for i=1:length(sessions)
                session = sessions(i);
                names{i} = session.sessionCode;
                switch(class(session.experiment))
                    case {'ArumeExperimentDesigns.SVVdotsAdaptFixed' 'ArumeExperimentDesigns.SVVLineAdaptFixed' 'ArumeExperimentDesigns.SVVForcedChoice'}
                        sds = session.trialDataSet;
                        sds(sds.TrialResult>0,:) = [];
                        sds(sds.Response<0,:) = [];
                        
                        if ( isempty(ds) )
                            ds = sds;
                        else
                            ds =[ds;sds]
                        end
                        
                end
            end
            
            figure
            
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( ds.Angle, ds.Response);
            
            plot( allAngles, allResponses,'o', 'color', [0.7 0.7 0.7], 'markersize',10,'linewidth',2)
            plot(a,p, 'color', 'k','linewidth',2);
            line([SVV, SVV], [0 100], 'color','k','linewidth',2);
        end
        
        function analysisResults = Analysis_SVV(this)
            
        end
        
        function analysisResults = Analysis_SVVUpDown(this)
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
end

