


classdef SPM < matlab.mixin.CustomDisplay
    properties
        df
        nNodes
        z
        r
        fwhm
        resels
        isregress = false;
    end
    
    properties (Hidden)
        STAT
        beta
        R
        sigma2
        roi
    end
    
    methods
        
        function [self] = SPM(STAT, z, df, fwhm, resels, varargin)
            %parse inputs:
            parser = inputParser;
            addOptional(parser, 'beta',      [], @(x)isnumeric(x));
            addOptional(parser, 'residuals', [], @(x)isnumeric(x) && ndims(x)>1 && ndims(x)<4 );
            addOptional(parser, 'sigma2',    [], @(x)isnumeric(x) && isvector(x) );
            addOptional(parser, 'roi',       [], @(x)isempty(x) || ((islogical(x)|| isnumeric(x)) && isvector(x))   );
            parser.parse(varargin{:});
            %assemble inputs:
            self.STAT     = STAT;
            self.z        = z;
            self.df       = df;
            self.fwhm     = fwhm;
            self.resels   = resels;
            self.nNodes   = numel(z);
            self.beta     = parser.Results.beta;
            self.R        = parser.Results.residuals;
            self.sigma2   = parser.Results.sigma2;
            self.roi      = parser.Results.roi;
            if ~isempty(self.roi)
                self.z(~self.roi) = nan;
            end
       end
       
       function spmi = inference(self, alpha, varargin)
            %parse inputs
            default2tailed = isequal(self.STAT,'T');
            parser         = inputParser;
            addOptional(parser, 'two_tailed', default2tailed, @islogical);
            addOptional(parser, 'withBonf', true, @islogical);
            parser.parse(varargin{:});
            two_tailed     = parser.Results.two_tailed;
            withBonf       = parser.Results.withBonf;
            %check two-tailed and test statistic
            if two_tailed && ~isequal(self.STAT, 'T')
                error('Two-tailed inference can only be used for t tests and regression.')
            end
            %check two-tailed and ROI
            if two_tailed && isnumeric(self.roi)
                error('Two-tailed inference can only be used with logical ROIs. Use true and false to define the ROI rather than -1, 0 and +1')
            end
            %correct for two-tailed inference
            if two_tailed
                pstar = alpha/2;
            else
                pstar = alpha;
            end
            %compute critical threshold
            zstar  = self.get_critical_threshold(pstar, withBonf);
            % compute supra-threshold cluster geometry:
            if isempty(self.roi)
                [extents,heights] = spm1d.geom.cluster_geom(self.z, zstar);
                if two_tailed
                    [extentsn,heightsn] = spm1d.geom.cluster_geom(-self.z, zstar);
                    extents = [extents extentsn];
                    heights = [heights heightsn];
                end
            else
                zz      = self.z;
                zz(~self.roi) = 0;
                extents1 = [];
                heights1 = [];
                if islogical(self.roi)
                    [extents,heights] = spm1d.geom.cluster_geom(zz, zstar);
                    if two_tailed
                        [extentsn,heightsn] = spm1d.geom.cluster_geom(-zz, zstar);
                        extents = [extents extentsn];
                        heights = [heights heightsn];
                    end
                else  %directional ROI
                    [bp,bn]  = deal(self.roi>0, self.roi<0);
                    any_pos  = any(bp) & any( zz(bp)>zstar );
                    any_neg  = any(bn) & any( zz(bn)<-zstar );
                    if any_pos
                        zzz       = zz;
                        zzz(self.roi<0) = 0;
                        [extents,heights] = spm1d.geom.cluster_geom(zzz, zstar);
                    end
                    if any_neg
                        zzz       = zz;
                        zzz(self.roi>0) = 0;
                        [extents1,heights1] = spm1d.geom.cluster_geom(-zzz, zstar);
                        heights1 = -1 * heights1;
                    end
                    if any_pos && any_neg
                        extents   = [extents extents1];
                        heights   = [heights heights1];
                    end
                    if ~any_pos
                        [extents,heights] = deal(extents1, heights1);
                    end
                end
            end
            % compute cluster-specific p values:
            if isempty(extents)
                p        = [];
            else
                extentsR    = extents / self.fwhm;  %extents in resel units
                p           = self.get_p_values(extentsR, heights, two_tailed, withBonf);
            end
            spmi        = spm1d.stats.spm.SPMi(self, alpha, zstar, p, two_tailed);
       end
       
       function plot(self)
           plot(self.z, 'linewidth',3, 'color','k')
       end
       
       
    end
   
    
    methods (Access=private)
        

                
                
        function [zstar] = get_critical_threshold(self, a, withBonf)
            [v,res,n] = deal(self.df, self.resels, self.nNodes);
            switch self.STAT
                case 'T'
                    zstar = spm1d.rft1d.t.isf_resels(a, v(2), res, 'withBonf',withBonf, 'nNodes',n);
                case 'X2'
                    zstar = spm1d.rft1d.chi2.isf_resels(a, v(2), res, 'withBonf',withBonf, 'nNodes',n);
                case 'F'
                    zstar = spm1d.rft1d.f.isf_resels(a, v, res, 'withBonf',withBonf, 'nNodes',n);
                case 'T2'
                    zstar = spm1d.rft1d.T2.isf_resels(a, v, res, 'withBonf',withBonf, 'nNodes',n);
            end
        end
        
        
        function [p] = get_p_values(self, kk, uu, two_tailed, withBonf)
            n = numel(kk);
            p = zeros(1,n);
            for i = 1:n
                p(i) = self.get_p_value(kk(i), uu(i), two_tailed, withBonf);
            end
        end
        
        
        function [p] = get_p_value(self, k, u, two_tailed, withBonf)
            [v,res,n] = deal(self.df, self.resels, self.nNodes);
            switch self.STAT
                case 'T'
                    p = spm1d.rft1d.t.p_cluster_resels(k, abs(u), v(2), res, 'withBonf',withBonf, 'nNodes',n);
                    if two_tailed
                        p = min(1, 2*p);
                    end
                case 'X2'
                    p = spm1d.rft1d.chi2.p_cluster(k, u, v(2), res, 'withBonf',withBonf, 'nNodes',n);
                case 'F'
                    p = spm1d.rft1d.f.p_cluster(k, u, v, Q, res, 'withBonf',withBonf, 'nNodes',n);
                case 'T2'
                    p = spm1d.rft1d.T2.p_cluster(k, u, v, Q, res, 'withBonf',withBonf, 'nNodes',n);
            end
%             [v,Q,w] = deal(self.df, self.nNodes, self.fwhm);
%             switch self.STAT
%                 case 'T'
%                     p = spm1d.rft1d.t.p_cluster(k, abs(u), v(2), Q, w);
%                     if two_tailed
%                         p = min(1, 2*p);
%                     end
%                 case 'X2'
%                     p = spm1d.rft1d.chi2.p_cluster(k, u, v(2), Q, w);
%                 case 'F'
%                     p = spm1d.rft1d.f.p_cluster(k, u, v, Q, w);
%                 case 'T2'
%                     p = spm1d.rft1d.T2.p_cluster(k, u, v, Q, w);
%             end
        end
    end
            
 
    methods (Access = protected)
        function header = getHeader(self)
            s = self.STAT;
            if s == 'T'
                s = 't';
            end
            header = sprintf('\nSPM{%s}',s);
        end
        
        function propgrp = getPropertyGroups(self)
            propList = struct(...
                'z', self.z,...
                'df', self.df,...
                'fwhm', self.fwhm,...
                'resels', self.resels);
         propgrp = matlab.mixin.util.PropertyGroup(propList);
        end
   end
            
    
end



