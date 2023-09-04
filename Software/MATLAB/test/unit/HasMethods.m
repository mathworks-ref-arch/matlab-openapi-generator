classdef HasMethods < matlab.unittest.constraints.Constraint
    % HasMethods - Constraint which checks whether a metaclass MethodList
    % contains methods with the specified names.
    properties(SetAccess = immutable)
        ExpectedMethods
    end
    
    methods
        function constraint = HasMethods(expectedMethods)
            constraint.ExpectedMethods = expectedMethods;
        end
        function bool = satisfiedBy(constraint,actual)
            bool = isempty(setdiff(constraint.ExpectedMethods,string({actual.MethodList.Name})));
            
        end

        function diag = getDiagnosticFor(constraint,actual)
            import matlab.unittest.diagnostics.StringDiagnostic
            d = setdiff(constraint.ExpectedMethods,string({actual.MethodList.Name}));
            if isempty(d)
                diag = StringDiagnostic('HasMethods Succeeded');
            else
                diag = StringDiagnostic(sprintf('HasMethods Failed: Methods not found: %s.',strjoin(d,', ')));
            end
        end        
    end
    
end