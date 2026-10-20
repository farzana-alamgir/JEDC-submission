function [trend, cycle] = hpfilter(y, lambda)
% HPFILTER Hodrick-Prescott filter
%   [TREND, CYCLE] = HPFILTER(Y, LAMBDA) filters the time series Y using
%   the Hodrick-Prescott filter with smoothing parameter LAMBDA.
%
%   The HP filter decomposes a time series into a trend and cyclical component.
%   Standard lambda values: 1600 for quarterly data, 100 for annual data.
%
%   Inputs:
%       Y      - Time series (vector or matrix). If matrix, filters each column
%       LAMBDA - Smoothing parameter (default: 1600)
%
%   Outputs:
%       TREND  - Trend component (same size as Y)
%       CYCLE  - Cyclical component (Y - TREND)

if nargin < 2
    lambda = 1600;  % Default for quarterly data
end

% Get dimensions
[nrows, ncols] = size(y);

% If y is a matrix, filter each column separately
if ncols > 1
    trend = zeros(size(y));
    for col = 1:ncols
        trend(:,col) = hpfilter(y(:,col), lambda);
    end
    if nargout > 1
        cycle = y - trend;
    end
    return;
end

% For single column/vector case
is_row = nrows == 1;

% Ensure y is a column vector for processing
if is_row
    y = y';
    n = length(y);
else
    n = nrows;
end

% Create second-difference matrix
e = ones(n,1);
D2 = spdiags([e -2*e e], 0:2, n-2, n);

% Solve HP filter equation: trend = (I + lambda*D'*D)^(-1) * y
% This is equivalent to minimizing: sum((y-trend)^2) + lambda*sum(diff(trend,2)^2)
I = speye(n);
trend = (I + lambda * (D2' * D2)) \ y;

% Restore original orientation
if is_row
    trend = trend';
end

if nargout > 1
    cycle = y - trend(:);
    if is_row
        cycle = cycle';
    end
end

end
