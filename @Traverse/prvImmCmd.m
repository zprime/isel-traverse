% Private function. Send a command expecting an immediate response
%
% % v0.1.0 2014-03-18
%
% Copyright (c) 2014, Zebb Prime and The University of Adelaide
% Licence appended to source
%
% See also Traverse/prvBlockCmd Traverse/Position Traverse/SetZero
function str = prvImmCmd( tro, cmd )

%% Disable the callback
cbf = get( tro.sp, 'BytesAvailableFcn' );
set( tro.sp, 'BytesAvailableFcn', [] );

%% Make sure the Timeout is reasonable
set( tro.sp, 'Timeout', 1 );

%% Send the command
if tro.verbose; fprintf( 1, 'Sending command (expecting immediate response): @0%s', cmd ); end;
fprintf( tro.sp, '@0%s', cmd );

st = fgetl( tro.sp );
errmsg = prvErrorMessages( tro );
% Look up the return value in the error message table
I = strcmp( st, errmsg(:,1) );
assert( sum(I)==1, 'traverse:spBACB:TooManyMatches', ...
  'Unknown error, or multiple error matches.');

% Output the error message to the terminal if required (without throwing an
% error)
if errmsg{I,3}
  fprintf(2,'%s\n',errmsg{I,2});
end

% Wait for the reply, which should be immediate
str = [];
while tro.sp.BytesAvailable > 0
  str = strcat( str, fgets( tro.sp ) );
end
if tro.verbose; fprintf( 1, 'Received status character %s, and string: ''%s''\n', st, str ); end;

%% Re-enable the callback (if it was present)
set( tro.sp, 'BytesAvailableFcn', cbf );

end