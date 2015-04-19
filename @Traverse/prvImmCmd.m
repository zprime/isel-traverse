% Private function. Send a command expecting an immediate response
%
% v0.2.1 2015-04-20
%
% Copyright (c) 2014--2015, Zebb Prime
% Licence appended to source
%
% See also Traverse/prvBlockCmd Traverse/Position Traverse/SetZero
function str = prvImmCmd( tro, cmd )

%% Disable the callback
cbf = get( tro.sp, 'BytesAvailableFcn' );
set( tro.sp, 'BytesAvailableFcn', '' );

%% Make sure the Timeout is reasonable
set( tro.sp, 'Timeout', 1 );

%% Send the command
if tro.verbose; fprintf( 1, 'Sending command (expecting immediate response): @0%s.\n', cmd ); end;
fprintf( tro.sp, '@0%s\n', cmd );

st = char( fread( tro.sp, 1 ) );
% Small delay to allow any other comms to finish.
pause(0.1);
errmsg = prvErrorMessages( tro );
% Look up the return value in the error message table
I = strcmp( st, errmsg(:,1) );
assert( sum(I)==1, 'traverse:spBACB:TooManyMatches', ...
  'Unknown error, or multiple error matches.');

% Wait for the reply, which should be immediate
str = [];
if tro.sp.BytesAvailable > 0
  str = char( fread( tro.sp, tro.sp.BytesAvailable ).' );
end
if tro.verbose; fprintf( 1, 'Received status character %s, and string: ''%s''\n', st, str ); end;

%% Re-enable the callback (if it was present)
set( tro.sp, 'BytesAvailableFcn', cbf );

% Now throw an error message
if errmsg{I,3}
  error( 'Traverse:prvImmCmd:ErrByte','Traverse error: %s\n',errmsg{I,2} );
end

end

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