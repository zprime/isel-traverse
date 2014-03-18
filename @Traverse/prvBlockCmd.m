% Private function. Send a command, then block until it is finished
%
% In gui mode, a small gui pops up, and clicking it, or pressing
% enter/esc/space will cause to movement to stop.
%
% In cmd mode, an invisible gui is created to stall the main thread.  The
% traverse movement can be stopped if the user presses ctrl-c
%
% In none, the traverse is issued an immediate version of the command, and
% the function returns immediately (i.e. no blocking)
%
% v0.1.0 2014-03-18
%
% Copyright (c) 2014, Zebb Prime and The University of Adelaide
% Licence appended to source
%
% See also Traverse/Move Traverse/MoveTo Traverse/Start Traverse/Abort
% Traverse/prvImmCmd
function prvBlockCmd( tro, cmd )

%% Switch between blocking modes
switch lower(tro.blockingMode)
  %% GUI blocking. Interruptable by clicking stop, enter, space or escape
  case 'gui'
    % Make sure the command is uppercase (for notify-when-complete)
    cmd = [ upper(cmd(1)), cmd(2:end) ];
    % Create a popup gui
    tro.hg = msgbox('Waiting for command to finish.','Waiting','modal');
    btnh = findobj( tro.hg, 'Tag', 'OKButton' );
    set( btnh, 'String', 'STOP', 'Callback', {@cbf,tro.sp}, 'KeyPressFcn', {@kpf,tro.sp} );
    drawnow;
    tro.waiting = true;
    
    % Transmit the command
    if tro.verbose; fprintf(1,'Writing blocking command: @0%s\n',cmd); end;
    fprintf(tro.sp,'@0%s\n',cmd);
    
    % Wait for the dialog to disappear (either return value or user)
    uiwait( tro.hg );
    if ~isempty( tro.hg )
      if ishandle( tro.hg );
        delete( tro.hg );
      end;
      tro.hg = [];
    end
    tro.waiting = false;

%% Command-line blocking, interruptable only by ctrl-c
  case 'cmd'
    % Make sure the command is uppercase (for notify-when-complete)
    cmd = [ upper(cmd(1)), cmd(2:end) ];
    
    % Set the waiting flag
    tro.waiting = true;

    % Transmit the command
    if tro.verbose; fprintf(1,'Writing blocking command: @0%s\n',cmd); end;
    fprintf(tro.sp,'@0%s\n',cmd);
    
    % Create an invisible figure we can wait for
    tro.hg = figure( 'visible', 'off' );
    waitfor( tro.hg );
    
    % If 'waiting' flag is still true: user-terminated
    if tro.waiting
      fwrite(tro.sp,char([255 13]));
      tro.waiting = false;
    end

%% No blocking - matlab will return before the traverse has finished moving    
  case 'none'
    % Make sure the command is lowercase (for notify immediately)
    cmd = [ lower(cmd(1)), cmd(2:end) ];
    % Transmit the non-blocking command
    if tro.verbose; fprintf(1,'Writing non-blocking command: @0%s\n',cmd); end;
    fprintf(tro.sp,'@0%s\n',cmd);
        
  otherwise
    error('traverse:prvBlockCmd:UnknownMode','Unknown blocking mode');
end

end

%% Keypress function for the gui blocking
function kpf( o, e, sp )
if any( strcmpi( e.Key, {'return','space','escape'} ) )
  fwrite(sp,char([253 13]));
  delete( ancestor(o,'figure') );
end
end

%% Callback function for the gui blocking
function cbf( o, ~, sp )
  fwrite(sp,char([253 13]));
  delete( ancestor(o,'figure') );
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