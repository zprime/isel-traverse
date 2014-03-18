% Retrieve the position of the traverse
%
% P = Position( t )
%
% OUTPUT:
%  P - 3 element vector, containing the traverse position in mm.
%
% v0.1.0 2014-03-18
%
% Copyright (c) 2014, Zebb Prime and The University of Adelaide
% Licence appended to source
%
% See also Traverse/MoveTo Traverse/Move
function P = Position( tro )
  assert( isconnected(tro), 'Traverse must be open to get the position.' );
  assert( ~isempty( tro.resolution ), 'Traverse resolution has not been set' );
  
  % Get the position as a string
  Pstr = prvImmCmd( tro, 'P' );
  
  % 3x24 bit numbers (6 hex digits)
  P = [ hex2dec(Pstr(1:6)), hex2dec(Pstr(7:12)), hex2dec(Pstr(13:18)) ];
  
  % 2's complement conversion
  b = 24;                             % Number of bits
  P = mod(P+2^(b-1),2^b)-2^(b-1);     % Conversion using mod
  
  % Convert to mm
  P = P(:) ./ tro.resolution(:);
end

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