% Control the 3D isel controlled traverses in the AWT and Thebarton
%
% Traverse is implemented as a Matlab object with auto-finding of the
% traverse, high-level commands and execution blocking with an option to
% immediately stop movement.
%
% Basic example:
% T = Traverse;
% Connect( T );
% ReturnToReference( T );   % Required for the Thebarton traverse
% Move( T, [100 50 75] );
%
% Traverse properties:
% blockingMode - {'gui','cmd','none'} - default is gui. This changes the
%                 way the traverse code waits for a movement to finish.
%              - gui creates a small popup that allows the user to stop the
%                 current movement.
%              - cmd blocks without using a gui. The user can still stop
%                 the command using ctrl-c.
%              - none - no blocking. Function calls return immediately
%                 without waiting for the movement to finish.
% resolution   - 3 element vector of traverse resolution in steps/mm. This
%                 is autodetected for the AWT and Theb. traverses.
% maxV         - 3 element vector of the maximum velocity of the traverse
%                 in mm/s. Autodetected for AWT and Theb. traverses.
%
% v0.1.0 2014-03-18
%
% Copyright (c) 2014, Zebb Prime and The University of Adelaide
% Licence appended to source
%
% see also Traverse/Connect Traverse/Disconnect Traverse/ReturnToReference
% see also Traverse/Move Traverse/MoveTo Traverse/Position Traverse/SetZero
% see also Traverse/Start
classdef Traverse < hgsetget
  
  % Hidden properties that the user shouldn't see
  properties ( Hidden = true, Access = private )
    sp = [];         % Serial-port object
    hg = [];         % Handle for the waiting popup.
    waiting = false; % Is the object waiting for a command to finish
  end
  
  % Publicly accessible properties
  properties ( SetAccess = public, GetAccess = public )
    verbose = false;
    blockingMode = 'gui';
    resolution = [];
    maxV = [];
  end
  
  methods
    % Constructor method
    function this = Traverse( varargin )
      ip = inputParser;
      ip.addParamValue('verbose',false, @(x) islogical(x) && isscalar(x) );
      ip.addParamValue('blockingMode','gui',@(x) any( strcmpi( x, {'gui','cmd','none'} ) ) );
      ip.parse( varargin{:} );
      
      this.verbose = ip.Results.verbose;
      this.blockingMode = ip.Results.blockingMode;
    end
    
    % Destructor method
    function delete( this )
      Disconnect( this );
    end
    
    % Property set methods (validity checking of setting properties)
    function set.verbose( this, value )
      assert( islogical(value) && isscalar(value), 'verbose must be either a scalar logical (true or false)' );
      this.verbose = value;
    end
    function set.blockingMode( this, value )
      assert( any( strcmpi( value, {'gui', 'cmd', 'none'} ) ), 'BlockingMode must be one of gui, cmd, or none' );
      ss = get(0,'ScreenSize');
      if isequal( ss(3:4), [1 1] )
        warning('Traverse:SetblockingMode:NoScreen','Can not use gui blocking when there is no display. Changing to ''cmd''.');
        value = 'cmd';
      end
      this.blockingMode = value;
    end
    function set.resolution( this, value )
      assert( isnumeric(value) && isreal(value), 'Resolution must be real and numeric.' );
      assert( numel(value)==3, 'Resolution must have 3 elements.' );
      assert( all(value>0), 'Resolution must be positive.' );
      assert( all(isfinite(value)), 'Resolution must be finite.' );
      assert( all(mod(value,1)==0), 'Resolution must be integers.' );
      this.resolution = value;
    end
    function set.maxV( this, value )
      assert( isnumeric(value) && isreal(value), 'Maximum velocity must be real and numeric.' );
      assert( numel(value)==3, 'Maximum velocity must have 3 elements.' );
      assert( all(value>0), 'Maximum velocity must be positive.' );
      assert( all(isfinite(value)), 'Maximum velocity must be finite.' );
      this.maxV = value;
    end
    
    % Save method. Prevent saving of an open serial port
    function b = saveobj(this)
      if isconnected( this )
        warning('traverse:save:connected','You should not save a connected traverse object.');
        Disconnect( this );
      end
      b = this;
    end
    
    % Test whether the traverse is connected
    function ic = isconnected( this )
      ic = ~isempty( this.sp );
    end
    
    % Disconnect
    function Disconnect( this )
      if isconnected( this )
        if strcmpi( this.sp.Status, 'open' )
          fclose( this.sp );
        end
        delete(this.sp);
        this.sp = [];
      end
    end
    
    % Disp method
    function disp( this )
      fprintf(1,'Traverse object.\n');
      % Connected?
      if isconnected(this)
        fprintf(1,'Status: connected on %s.\n',this.sp.Port);
      else
        fprintf(1,'Status: disconnected.\n');
      end
      % Blocking mode
      fprintf(1,'Blocking mode: %s.\n',this.blockingMode);
      % Resolution
      if ~isempty(this.resolution)
        fprintf(1,'Axis resolutions: [%.0f %.0f %.0f] points/mm.\n',this.resolution);
      else
        fprintf(1,'Axis resolution not autodetected or set.\n');
      end
      % Maximum velocity
      if ~isempty(this.maxV)
        fprintf(1,'Maximum axis velocities: [%.0f %.0f %.0f] mm/s.\n',this.maxV);
      else
        fprintf(1,'Maximum axis velocities not autodetected or set.\n');
      end
      if this.verbose
        fprintf(1,'Verbose mode is on.\n');
      end
    end
    
    
    
    % External methods
    Connect( tro, varargin );
    ReturnToReference( tro );
    Move( tro, p, s );
    MoveTo( tro, p, s );
    Start( tro );
    Abort( tro );
    P = Position( tro );
    SetZero( tro );
    end % of methods
  
    
    
    % Private methods
    methods (Hidden = true)
      str = prvImmCmd( tro, cmd );
      prvBlockCmd( tro, cmd );
      errmsg = prvErrorMessages( tro );
    end
    
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