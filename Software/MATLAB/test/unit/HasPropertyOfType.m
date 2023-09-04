classdef HasPropertyOfType < matlab.unittest.constraints.Constraint
    % HasPropertyOfType - Constraint which checks whether a metaclass
    % PropertyList contains a property with the specified name and whether
    % it is of the specified type.
    properties(SetAccess = immutable)
        PropertyName
        PropertyType
    end
    
    methods
        function constraint = HasPropertyOfType(name,type)
            constraint.PropertyName = name;
            constraint.PropertyType = type;
        end
        function bool = satisfiedBy(constraint,actual)
            i = {actual.PropertyList.Name} == constraint.PropertyName;
            bool = any(i) && actual.PropertyList(i).Validation.Class == constraint.PropertyType;
        end

        function diag = getDiagnosticFor(constraint,actual)
            import matlab.unittest.diagnostics.StringDiagnostic
            i = {actual.PropertyList.Name} == constraint.PropertyName;
            if ~any(i)
                diag = StringDiagnostic( ...
                    sprintf('HasPropertyOfType failed: property "%s" not found.', ...
                    constraint.PropertyName));
                return;
            end
            if actual.PropertyList(i).Validation.Class ~= constraint.PropertyType
                diag = StringDiagnostic( ...
                    sprintf('HasPropertyOfType failed: type verification failed for property "%s", expected "%s" actual "%s".', ...
                    constraint.PropertyName,constraint.PropertyType.Name,actual.PropertyList(i).Validation.Class.Name));
                return;
            end
            diag = StringDiagnostic('HasPropertyOfType succeeded');
        end        
    end
    
end