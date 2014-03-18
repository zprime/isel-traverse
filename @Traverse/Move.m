% Perform a relative traverse movement
%
% Move( tro, p, s )
%
% INPUTS:
%  tro - Traverse object
%  p - [3x1] Distance to move to in mm
%  s (optional) - if scalar, fraction of maximum speed. If [3x1], the
%                 fraction of maximum speed for each channel. If omitted,
%                 defaults to 0.5.
%
% v0.1.0 2014-03-18
%
% Copyright (c) 2014, Zebb Prime and The University of Adelaide
% Licence appended to source
%
% See also Traverse/MoveTo
function Move( tro, p, s )

% Check the input arguments
narginchk(2,3);
assert( isconnected(tro), 'Traverse object must be connected to move.');
assert( isnumeric(p) && isreal(p) && all(isfinite(p)) && numel(p)==3,'Position must be a numeric, real, finite vector with 3 values');
if nargin>=3
  assert( isnumeric(s) && isreal(s) && all(isfinite(s)) && any(numel(s)==[1 3]) && s>0 && s<=1,'Second parameter must be single fraction of maximum speed, or a vector of fractions of maximum speed.');
else
  s = 0.5;
end

% Check the traverse object properties
assert( ~isempty( tro.resolution ), 'Traverse resolution has not been set' );
assert( ~isempty( tro.maxV ), 'Maximum velocity has not been set' );

% Calculate movement time
t = max( abs( p(:) ) ./ tro.maxV(:) ./ s );
if tro.verbose; fprintf(1,'Traverse movement will take approx %.1fs.\n',t); end;
assert( isfinite(t) && t>0 && numel(t)==1, 'Something has gone wrong with t.' );

% Calculate velocity and position in Hz and points
V = max( min( round( tro.resolution(:) .* p(:) ./ t ), 10000 ), 30 );
X = max( min( round( tro.resolution(:) .* p(:) ), 2^23-1 ), -2^23 );

% Generate the command string
cmd = sprintf(1,'A %.0f,%.0f,%.0f,%.0f,%.0f,%.0f,0,30',[X.';V.']);

% Actually do the movement
prvBlockCmd( tro, cmd );

%{
Copyright (c) 2014, Zebb Prime and The University of Adelaide
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the organization nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL ZEBB PRIME BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%}