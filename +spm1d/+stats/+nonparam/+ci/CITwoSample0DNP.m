%__________________________________________________________________________
% Copyright (C) 2016 Todd Pataky
% $Id: SPM0D.m 1 2016-01-04 16:07 todd $


classdef CITwoSample0DNP <  spm1d.stats.ci.CITwoSample0D
    methods
        function [self] = CITwoSample0DNP(snpmi, mA, mB, hstar, mu)
            self @ spm1d.stats.ci.CITwoSample0D(snpmi, mA, mB, hstar, mu)
            self.name = '0D Non-Parametric Confidence Interval';
            self.isparametric  = false;
        end
    end
end