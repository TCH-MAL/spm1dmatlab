%__________________________________________________________________________
% Copyright (C) 2016 Todd Pataky
% $Id: SPM.m 2 2016-03-30 17:01 todd $


classdef PermuterANOVA1rm0D < spm1d.stats.nonparam.permuters.APermuterANOVA & spm1d.stats.nonparam.permuters.APermuter0D
    methods
        function [self] = PermuterANOVA1rm0D(y, A, SUBJ)
            self@spm1d.stats.nonparam.permuters.APermuterANOVA(y, A, 'SUBJ',SUBJ)
            self.calc           = spm1d.stats.nonparam.calculators.CalculatorANOVA1rm(self.A, self.SUBJ);
        end
    end
end



