% Perform an absolute traverse movement
%
% MoveTo( tro, p, s )
%
% INPUTS:
%  tro - Traverse object
%  p - [3x1] Distance to move to in mm
%  s (optional) - if scalar, fraction of maximum speed. If [3x1], the
%                 fraction of maximum speed for each channel. If omitted,
%                 defaults to 0.5.
%
% v0.2.0 2015-03-17
%
% Copyright (c) 2014--2015, Zebb Prime
% Licence appended to source
%
% See also Traverse/Move
function MoveTo( tro, p, s )

% Check the input arguments
narginchk(2,3);
movevalid( tro );
assert( isnumeric(p) && isreal(p) && all(isfinite(p)) && numel(p)==3,'Position must be a numeric, real, finite vector with 3 values');
if nargin>=3
  assert( isnumeric(s) && isreal(s) && all(isfinite(s)) && isscalar(s) && s>=0 && s<=1,'Second parameter must be single fraction of maximum speed.');
else
  s = 0.5;
end

% Distance to travel
P = tro.Position();
D = abs( ( p(:) - P(:) ).*tro.resolution(:) );

% Velocities, as a fraction of required fraction
V = s.*( tro.maxV(:).*tro.resolution(:) );

% Indicies of which axes will move when
if tro.interp3D
  I1 = [1 2 3];
  I2 = [];
else
  switch lower( tro.interp2Daxes )
    case 'xy'
      I1 = [1 2];
      I2 = 3;
    case 'xz'
      I1 = [1 3];
      I2 = 2;
    case 'yz'
      I1 = [2 3];
      I2 = 1;
  end
end

% First movement
V1 = V(I1);
[Dm,Im] = max( D(I1) );
t1 = Dm./V1(Im);
V1 = D(I1)./t1;
V(I1) = V1;

% Second movement
if ~isempty( I2 )
  t2 = D(I2)./V(I2);
else
  t2 = 0;
end

% Check velocity value formats
V = max( min( round(V), 10000 ), 30 );
  
% Display approx movement time
if tro.verbose; fprintf(1,'Traverse movement will take approx %.1fs.\n',t1+t2); end;

% Movement destination in points
X = max( min( round( tro.resolution(:) .* p(:) ), 2^23-1 ), -2^23 );

% Generate the command string
cmd = sprintf('M %.0f,%.0f,%.0f,%.0f,%.0f,%.0f,0,30',[X.';V.']);

% Actually do the movement
prvBlockCmd( tro, cmd );

%{
Copyright (c) 2014--2015, Zebb Prime
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