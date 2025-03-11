classdef SemVer
    % SEMVER Class to support sematic versioning
    % Supports 3 value numeric versions only e.g.: 1.2.3
    % Support PR label strings e.g. 1.2.3-beta and +<metadata> values.
    % See: https://semver.org
    % Assumes numeric fields are non negative.
    % Numeric fields are stored as int32 values.
    %
    % Examples:
    %   % No arguments, returns a value of 0.0.0
    %   import <namepace>.SemVer
    %   x = SemVer();
    %
    %   % Overrides for > < >= <= ==
    %   x = SemVer("1.2.3");
    %   y = SemVer("1.2.4");
    %   >> x > y
    %   ans =
    %     logical
    %      0
    %
    %   >> gt(x,y)
    %   ans =
    %     logical
    %      0

    % Copyright 2022-2025 The MathWorks, Inc.

    % TODO
    % Consider performance

    properties
        major int32 = 0
        minor int32 = 0
        patch int32 = 0
        prerelease string = ""
        metadata string = ""
    end

    properties (Hidden)
        baseErrorPrefix
    end

    methods
        function obj = SemVer(varargin)

            obj.baseErrorPrefix = replace(upper(class(obj)), '.', ':');

            if nargin == 1
                % Input of type semver, a character vector or scalar string or string array
                % A string array will be joined with no delimiters
                switch class(varargin{1})
                    case class(obj)
                        obj = varargin{1};

                    case 'char'
                        [major,minor,patch,prerelease,metadata] = str2SemVer(obj, varargin{1});
                        obj.major = major;
                        obj.minor = minor;
                        obj.patch = patch;
                        obj.prerelease = prerelease;
                        obj.metadata = metadata;

                    case 'string'
                        for n = 1:numel(varargin{1})
                            [major,minor,patch,prerelease,metadata] = str2SemVer(obj, varargin{1}(n));
                            obj(n).major = major; %#ok<AGROW>
                            obj(n).minor = minor; %#ok<AGROW>
                            obj(n).patch = patch; %#ok<AGROW>
                            obj(n).prerelease = prerelease; %#ok<AGROW>
                            obj(n).metadata = metadata; %#ok<AGROW>
                        end
                        % TODO error(obj.baseErrorPrefix, 'Single string arguments must be scalar.');

                    otherwise
                        error(obj.baseErrorPrefix, 'Unexpected argument type: %s', class(varargin{1}));
                end
            elseif nargin == 0
                % Do nothing, default class instance, 0.0.0
            else
                error(obj.baseErrorPrefix, 'Unsupported number of varargin arguments: %d', length(varargin));
            end

            % Some minimal validation
            for n = 1:numel(obj)
                if isempty(obj(n).major)...
                        || isempty(obj(n).minor)...
                        || isempty(obj(n).patch)...
                        || isempty(obj(n).prerelease)...
                        || isempty(obj(n).metadata)
                    error(obj(n).baseErrorPrefix, 'SemVer object has an empty property.');
                end
            end
        end


        function tf = inRange(obj, lowerVer, upperVer)
            % INRANGE Returns true if version is >= lowerVer and <= upperVer

            arguments
                obj (1,1)
                lowerVer (1,:)
                upperVer (1,:)
            end

            if obj.ge(lowerVer) && obj.le(upperVer)
                tf = true;
            else
                tf = false;
            end
        end


        function tf = eq(obj, ver)
            % EQ Returns true if the version is equal to the object's value
            arguments
                obj (1,1)
                ver (1,:)
            end

            result = obj.compareVersions(obj, ver);

            if result == 0
                tf = true;
            else
                tf = false;
            end
        end


        function tf = ne(obj, ver)
            % NE Returns true if the version is not equal to the object's value
            arguments
                obj (1,1)
                ver (1,:)
            end

            tf = ~obj.eq(ver);
        end


        function tf = lt(obj, ver)
            % LT Returns true if the version is less than the object's value
            arguments
                obj (1,1)
                ver (1,:)
            end

            result = obj.compareVersions(obj, ver);

            if result == -1
                tf = true;
            else
                tf = false;
            end
        end


        function tf = le(obj, ver)
            % LE Returns true if the version is less than or equal to the object's value
            arguments
                obj (1,1)
                ver (1,:)
            end

            result = obj.compareVersions(obj, ver);

            if result == -1 || result == 0
                tf = true;
            else
                tf = false;
            end
        end


        function tf = gt(obj, ver)
            % GT Returns true if the version is greater than the object's value
            arguments
                obj (1,1)
                ver (1,:)
            end

            result = obj.compareVersions(obj, ver);

            if result == 1
                tf = true;
            else
                tf = false;
            end
        end


        function tf = ge(obj, ver)
            % GE Returns true if the version is greater than or equal to the object's value
            arguments
                obj (1,1)
                ver (1,:)
            end

            result = obj.compareVersions(obj, ver);

            if result == 1 || result == 0
                tf = true;
            else
                tf = false;
            end
        end


        function str = toString(obj)
            % TOSTRING Returns the version as a field separated string, metadata is included if present
            arguments
                obj (1,1)
            end

            str = string(sprintf('%d.%d.%d', obj.major, obj.minor, obj.patch));
            if strlength(obj.prerelease) > 0
                str = str + "-" + obj.prerelease;
            end
            if strlength(obj.metadata) > 0
                str = str + "+" + obj.metadata;
            end
        end
    end


    methods(Hidden)
        function obj = strArray2SemVer(obj, str)
            arguments
                obj (1,1)
                str string {mustBeNonzeroLengthText}
            end

            if numel(str) == 0 || numel(str) > 5
                error(obj.baseErrorPrefix, 'Invalid version value: %s', str);
            end

            if numel(str) >= 1
                obj.major = conv2int32(str(1));
            end
            if numel(str) >= 2
                obj.minor = conv2int32(str(2));
            end
            if numel(str) >= 3
                obj.patch = conv2int32(str(3));
            end
            if numel(str) >= 4
                obj.prerelease = str(4);
            end
            if numel(str) == 5
                obj.metadata = str(5);
            end
        end


        function [major,minor,patch,prerelease,metadata] = str2SemVer(obj, str)
            arguments
                obj
                str string {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            major = int32(0);
            minor = int32(0);
            patch = int32(0);
            prerelease = ""; %#ok<NASGU>
            metadata = "";

            % strip any + and following fields
            if contains(str, '+')
                prePlusStr = extractBefore(str, '+');
                if strlength(prePlusStr) == 0
                    error(obj.baseErrorPrefix, 'Invalid version value: %s', str);
                end
                metadata = extractAfter(str, '+');
            else
                prePlusStr = str;
            end

            if startsWith(prePlusStr, '-')
                error(obj.baseErrorPrefix, 'Invalid version value: %s', str);
            end

            if contains(prePlusStr, '-')
                prerelease = extractAfter(prePlusStr, '-');
                mmpStr = extractBefore(prePlusStr, '-');
            else
                prerelease = "";
                mmpStr = prePlusStr;
            end

            verFields = split(mmpStr, '.')';
            if numel(verFields) == 0 || numel(verFields) > 3
                % A true sematic version should not have 4 dotted fields
                % e.g. 1.2.3.4
                error(obj.baseErrorPrefix, 'Invalid version value: %s', str);
            end
            if numel(verFields) >= 1
                major = conv2int32(verFields(1));
            end
            if numel(verFields) >= 2
                minor = conv2int32(verFields(2));
            end
            if numel(verFields) >= 3
                patch = conv2int32(verFields(3));
            end
        end
    end


    methods(Static)
        function result = compareVersions(ver1, ver2)
            % compareVersions Compares two Semantic Version values
            % If they are equal 0 is returned.
            % If ver1 is less than v2 -1 is returned.
            % If ver1 is greater than v2 1 is returned.

            arguments
                ver1 (1,:)
                ver2 (1,:)
            end

            ver1 = openapi.internal.SemVer(ver1);
            ver2 = openapi.internal.SemVer(ver2);

            result = compareOneNumericLevel(ver1.major, ver2.major);
            if result ~= 0
                return;
            end

            result = compareOneNumericLevel(ver1.minor, ver2.minor);
            if result ~= 0
                return;
            end

            result = compareOneNumericLevel(ver1.patch, ver2.patch);
            if result ~= 0
                return;
            end

            result = comparePR(ver1.prerelease, ver2.prerelease);
        end


        function result = sort(verVals, direction)
            % sort Sort an array of Sematic Version values
            % direction can be either ascending or descending.
            % The default is ascending.
            % An array of SemVer is returned.

            % Crude implementation intended for sorting small arrays only where
            % performance is not a primary concern.

            arguments
                verVals (1,:)
                direction (1,1) string {mustBeTextScalar, mustBeNonzeroLengthText, mustBeMember(direction,{'ascending','descending'})} = "ascending"
            end

            if strcmpi(direction, 'ascending')
                ascending = true;
            else
                ascending = false;
            end

            if isstring(verVals)
                result = openapi.internal.SemVer(verVals);
            elseif endsWith(class(verVals), '.SemVer')
                result = verVals;
            else
                error("SEMVER:sort", 'Argument must be of type SemVer or string.');
            end

            for n = 1:numel(result)
                for m = 1:numel(result)-1
                    if ascending
                        if result(m).gt(result(m+1))
                            tempVal = result(m+1);
                            result(m+1) = result(m);
                            result(m) = tempVal;
                        end
                    else
                        if result(m).lt(result(m+1))
                            tempVal = result(m+1);
                            result(m+1) = result(m);
                            result(m) = tempVal;
                        end
                    end
                end
            end
        end


        function result = compareAlpha(ver1, ver2)
            % comparAlpha Compares two Semantic Version values
            % If they are equal 'eq' is returned as a character vector.
            % If ver1 is less than v2 'lt' is returned as a character vector.
            % If ver1 is greater than v2 'gt' is returned as a character vector.

            arguments
                ver1 (1,:)
                ver2 (1,:)
            end

            ver1 = openapi.internal.SemVer(ver1);

            resultNumeric = ver1.compareVersions(ver1, ver2);

            if resultNumeric == 0
                result = 'eq';
            elseif resultNumeric == 1
                result = 'gt';
            elseif resultNumeric == -1
                result = 'lt';
            else
                error(ver1.baseErrorPrefix, 'Comparison failed: %f', resultNumeric);
            end
        end
    end
end


function tf = preq(v1, v2) %#ok<DEFNU>
    arguments
        v1 string {mustBeTextScalar, mustBeNonzeroLengthText}
        v2 string {mustBeTextScalar, mustBeNonzeroLengthText}
    end
    tf = strcmp(v1, v2);
end


function result = compareOneNumericLevel(v1, v2)
    arguments
        v1 (1,1) int32
        v2 (1,1) int32
    end

    if v1 < v2
        result = -1;
    elseif v1 > v2
        result = 1;
    else
        result = 0;
    end
end


function result = conv2int32(input)
    arguments
        input string {mustBeTextScalar, mustBeNonzeroLengthText}
    end

    val = str2double(input);
    if isnan(val)
        result = int32(0);
    else
        result = int32(val);
    end
end


function result = comparePRField(prf1, prf2)
    arguments
        prf1 string {mustBeTextScalar}
        prf2 string {mustBeTextScalar}
    end

    % maxcharacters = 10 from strlength(string(intmax))
    digitsPat = digitsPattern(1,10);
    prf1IsNumeric = any(matches(prf1, digitsPat));
    prf2IsNumeric = any(matches(prf2, digitsPat));
    alphaExp = "[a-zA-Z-]";
    if strlength(prf1) == numel(regexp(prf1, alphaExp))
        prf1IsAlpha = true;
    else
        prf1IsAlpha = false;
    end
    if strlength(prf2) == numel(regexp(prf2, alphaExp))
        prf2IsAlpha = true;
    else
        prf2IsAlpha = false;
    end

    if ~prf1IsNumeric && ~prf1IsAlpha
        error("SEMVER:comparePRField", 'Invalid prerelease field: %s', prf1);
    end
    if ~prf2IsNumeric && ~prf2IsAlpha
        error("SEMVER:comparePRField", 'Invalid prerelease field: %s', prf2);
    end

    % Numeric identifiers always have lower precedence than non-numeric identifiers
    if prf1IsNumeric && prf2IsAlpha
        result = -1;
        return;
    end
    if prf1IsAlpha && prf2IsNumeric
        result = 1;
        return;
    end

    % Identifiers consisting of only digits are compared numerically.
    if prf1IsNumeric && prf2IsNumeric
        result = compareOneNumericLevel(conv2int32(prf1), conv2int32(prf2));
        return;
    end

    % Identifiers with letters or hyphens are compared lexically in ASCII sort order.
    if prf1IsAlpha  && prf2IsAlpha
        % pr1 > pr2
        if strlength(prf1) == 0 && strlength(prf2) > 0
            result = 1;
            return;
        end
        % pr1 < pr2
        if strlength(prf1) > 0 && strlength(prf2) == 0
            result = -1;
            return;
        end

        if prf1 > prf2
            result = 1;
        elseif prf1 < prf2
            result = -1;
        elseif prf1 == prf2
            result = 0;
        else
            error("SEMVER:comparePRField", 'Invalid state.');
        end
        return;
    end
    error("SEMVER:comparePRField", 'Unable to compare: %s and %s', prf1, prf2);
end


function result = comparePR(pr1, pr2)
    arguments
        pr1 string {mustBeTextScalar}
        pr2 string {mustBeTextScalar}
    end

    % Short circuit cases where there is only one value
    % no need to look at the values

    % Simple check for equality, also covers "" == ""
    % pr1 == pr2
    if strcmp(pr1, pr2)
        result = 0;
        return;
    end

    % No prerelease has higher precedence than a prerelease
    % pr1 > pr2
    if strlength(pr1) == 0 && strlength(pr2) > 0
        result = 1;
        return;
    end
    % pr1 < pr2
    if strlength(pr1) > 0 && strlength(pr2) == 0
        result = -1;
        return;
    end

    %% full comparison needed

    pr1fields = split(pr1, '.');
    pr2fields = split(pr2, '.');
    leastFields = min(numel(pr1fields), numel(pr2fields));

    % Stop comparing when the first PR runs out of fields
    result = [];
    for n = 1:leastFields
        cmp = comparePRField(pr1fields(n), pr2fields(n));
        if cmp == 1
            result = 1;
            break
        elseif cmp == -1
            result = -1;
            break
        elseif cmp == 0
            % keep going through fields, no break
            result = 0;
        else
            error("SEMVER:comparePR", "Invalid return from comparePRField().");
        end
    end
    if result == 0
        if numel(numel(pr1fields)) > numel(pr2fields)
            result = 1;
        elseif numel(numel(pr1fields)) < numel(pr2fields)
            result = -1;
        elseif numel(numel(pr1fields)) == numel(pr2fields)
            result = 0;
        else
            error("SEMVER:comparePR", "Invalid state.");
        end
    end
end