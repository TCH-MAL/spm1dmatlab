%__________________________________________________________________________
% Copyright (C) 2016 Todd Pataky
% $Id: SPM.m 2 2016-03-30 17:01 todd $


classdef PermuterANOVA2rm_1D < spm1d.stats.nonparam.permuters.APermuterANOVA1DmultiF
    methods
        function [self] = PermuterANOVA2rm_1D(y, A, B, SUBJ)
            self@spm1d.stats.nonparam.permuters.APermuterANOVA1DmultiF(y, A, B, 'SUBJ', SUBJ)
            self.calc           = spm1d.stats.nonparam.calculators.CalculatorANOVA2rm(self.A, self.B, self.SUBJ);
            self.nEffects       = 3;
        end
    end
end



