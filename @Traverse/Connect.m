% Connect to a traverse.
%
% Searches serial ports for a isel controller. Port and Baud can be
% manually specified if requried.
%
% Optional key-value pair inputs
% KEY    | VALUE
% ---------------------------------
% 'port' | Valid serial port name. If none specified, the code enumerates
%        |  all available ports.
% 'baud' | Baud rate to connect at. If none specified, the code enumerates
%        |  over valid baud rates.
%
% v0.2.0 2015-04-17
%
% Copyright (c) 2014--2015, Zebb Prime
% Licence appended to source
function Connect( tro, varargin )

%% Parse the inputs
ip = inputParser;
ip.addRequired( 'tro', @(x) isa(x,'Traverse') );
ip.addParamValue( 'port', [], @ischar );
ip.addParamValue( 'baud', [], @ischar );
ip.parse( tro, varargin{:} );

%% Serial ports and bauds to search if not specified
if isempty( ip.Results.port )
  instrreset;
  as = instrhwinfo('serial');
  ports = as.AvailableSerialPorts;
  if tro.verbose; fprintf(1,'Enumerating available serial ports:\n'); fprintf(1,'%s\n',ports{:}); end;
else
  ports = {ip.Results.port};
  if tro.verbose; fprintf(1,'Using user-supplied serial port %s\n',ports{:}); end;
end

if isempty( ip.Results.baud )
  bauds = {9600,19200};
  if tro.verbose; fprintf(1,'Enumerating default baud rates:\n'); fprintf(1,'%i\n',bauds{:}); end;
else
  bauds = {ip.Results.baud};
  if tro.verbose; fprintf(1,'Using user-supplied baud rate %s\n',bauds{:}); end;
end

%% Iterate over the ports and baud rates until a valid port is found
% Default port settings
sp = serial( 'dummy', 'terminator', 'CR', 'InputBufferSize', 2048, 'Timeout', 1, 'BytesAvailableFcnMode', 'byte', 'BytesAvailableFcnCount', 1 );

[Ip,Ib] = meshgrid( 1:numel(ports), 1:numel(bauds) );
isvalid = false;
for ii=1:numel(Ip)
  % Change to port/baud being enumerated
  set( sp, 'Port', ports{Ip(ii)}, 'Baud', bauds{Ib(ii)} );
  if tro.verbose; fprintf(1,'Attempting contact on %s at %i\n',ports{Ip(ii)},bauds{Ib(ii)}); end;
  
  try
    % Try to open the port, and communicate with the isel box
    fopen(sp);
    fprintf(sp,'@0?\n');
    pause(0.5);
    
    % If nothing is available, try again
    if sp.BytesAvailable==0
      if tro.verbose; fprintf(1,'No response.\n'); end;
      fclose(s);
      continue;
    end
    
    % Return string
    retst = char( fread(sp,sp.BytesAvailable).' );
    if regexpi( retst, 'isel' )
      if tro.verbose; fprintf(1,'isel controlled traverse found on %s at %i.\n',ports{Ip(ii)},bauds{Ib(ii)}); end;
      isvalid = true;
      break;
    end
    
  catch
    if tro.verbose; fprintf(1,'Failed with an error.\n'); end;
    if strcmpi( sp.Status, 'open' )
      fclose(sp);
    end
  end
end

%% If a valid connection was established, initialise traverse
if isvalid
    assert( exist('retst','var')~=0, 'Internal error: return string not available.' );
    pause(3);
    char( fread(sp,sp.BytesAvailable).' );
    fprintf( sp, '@07\n' );
    spBytesAvailableFcnCB( sp, [], tro );
end

%% If after all that, see if we have a valid connection
if ~isvalid
  delete(sp);
  error('traverse:connect:UnableToConnect','Unable to connect to an isel controlled traverse.');
end

%% Set up the callback
set( sp, 'BytesAvailableFcn', {@spBytesAvailableFcnCB,tro} );

%% Save serial object to traverse object
tro.sp = sp;

%% Try and put the traverse into 3D mode
try
  tro.interp3D = true;
catch
end

end


% Private callback function to read return value from the traverse
function spBytesAvailableFcnCB( obj, ~, tro )

% If there was a waiting dialog, close it
if ~isempty(tro.hg)
  if ishandle( tro.hg )
    delete(tro.hg);
  end
  tro.hg = [];
end

% Set waiting to false, to resume operation (if paused)
tro.waiting = false;

% Now lets look at the data to see what happened
st = char( fread( obj, 1 ) );
if tro.verbose; fprintf(1,'isel returned: %s\n',st); fprintf(1,'%i ',uint8(st)); fprintf(1,'\n'); end;

% Expected only 1 character during normal operation
assert( numel(st) == 1, 'traverse:spBACB:UnknownString',...
  'isel controller returned more than one character.');

errmsg = prvErrorMessages( tro );

% Look up the return value in the error message table
I = strcmp( st, errmsg(:,1) );
assert( sum(I)==1, 'traverse:spBACB:TooManyMatches', ...
  'Unknown error, or multiple error matches.');

if errmsg{I,3}
  fprintf(2,'%s\n',errmsg{I,2});
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