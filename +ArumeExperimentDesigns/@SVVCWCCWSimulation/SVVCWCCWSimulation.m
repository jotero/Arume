classdef SVVCWCCWSimulation < ArumeExperimentDesigns.SVVCWCCW
    
    properties
        
    end
    
    % ---------------------------------------------------------------------
    % Options to set at runtime
    % ---------------------------------------------------------------------
    methods ( Static = true )
        function dlg = GetOptionsStructDlg( this )
            dlg.UseGamePad = { {'0','{1}'} };
            dlg.SVV = 0;
            dlg.SVVstd = 1;
            
            dlg.SVVWaveFreq = 0;
            dlg.SVVWaveAmplitude = 0;
            dlg.SVVWavePhase = 0;
        end
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function trialResult = runTrial( this, variables )
            
            try
                this.lastResponse = -1;
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                                
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
              
                angle1 = 0;
                switch(variables.Direction)
                    case 'CW'
                        angle1 = variables.Angle;
                    case 'CCW'
                        angle1 = -variables.Angle;
                end
                
                ntrials = size(this.Session.CurrentRun.pastConditions,1);
                SVV = this.ExperimentOptions.SVV + this.ExperimentOptions.SVVWaveAmplitude*sin(ntrials*this.ExperimentOptions.SVVWaveFreq*2*pi + this.ExperimentOptions.SVVWavePhase);
                t = 1./(1+exp(-(angle1-SVV)/this.ExperimentOptions.SVVstd));
                
                this.lastResponse = 1+(1-(rand(1)>t));
                
            catch ex
                %  this.eyeTracker.StopRecording();
                rethrow(ex)
            end
            
            
            if ( this.lastResponse < 0)
                trialResult =  Enum.trialResult.ABORT;
            end
            
            % this.eyeTracker.StopRecording();
            
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
    end
    
    % ---------------------------------------------------------------------
    % Other methods
    % ---------------------------------------------------------------------
    methods( Access = public )
    end
end
