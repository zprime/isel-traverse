% Control traverses using isel controllers
%
% Traverse is implemented as a Matlab object with auto-finding of the
% traverse, high-level commands and execution blocking with an option to
% immediately stop movement.
%
% Basic example:
% T = Traverse;
% Connect( T );
% set( T, 'resolution', [80 80 160], 'maxV', [40 40 25] );
% ReturnToReference( T );
% MoveTo( T, [100 50 75] );
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
% interp3D     - Scalar logical, defaults to true for devices that support
%                 it. True puts the controller in 3D interpolation mode
%                 (if supported by the device).  In 3D interpolation mode,
%                 all three axes move at the same time.  In 2D mode 
%                 (interp3D=false), the two axes in interp2Daxes move at
%                 the same time, followed by the third axis.
% interp2Daxes - {'XY','XZ','YZ'} - default is XY. When interp3D is false,
%                 (2D interp mode), these two axes will move first,
%                 followed by the third axis.
%
% v0.1.0 2015-04-17
%
% Copyright (c) 2014--2015, Zebb Prime
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
    interp3D = false;
    interp2Daxes = 'XY';
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
    % Sanity check resolution setting
    function set.resolution( this, value )
      assert( isnumeric(value) && isreal(value), 'Resolution must be real and numeric.' );
      assert( numel(value)==3, 'Resolution must have 3 elements.' );
      assert( all(value>0), 'Resolution must be positive.' );
      assert( all(isfinite(value)), 'Resolution must be finite.' );
      assert( all(mod(value,1)==0), 'Resolution must be integers.' );
      this.resolution = value;
    end
    % Sanity check maximum velocity setting
    function set.maxV( this, value )
      assert( isnumeric(value) && isreal(value), 'Maximum velocity must be real and numeric.' );
      assert( numel(value)==3, 'Maximum velocity must have 3 elements.' );
      assert( all(value>0), 'Maximum velocity must be positive.' );
      assert( all(isfinite(value)), 'Maximum velocity must be finite.' );
      this.maxV = value;
    end
    % Sanity check, and see if device supports, 3D interp mode setting
    function set.interp3D( this, value )
      assert( islogical(value) && isscalar(value), 'Interp3D must be a logical scalar' );
      assert( isconnected( this ), 'Traverse must be connected.' );
      try
        if value
          prvImmCmd( this, 'z1' );
          this.interp3D = true;
        else
          prvImmCmd( this, 'z0' );
          this.interp3D = false;
        end
      catch
        error('Traverse:interp3D:unable','Unable to change 3D interpolation mode');
      end
    end
    % Sanith check and set the two axes for 2D interpolation
    function set.interp2Daxes( this, value )
      assert( ischar( value ), '2D interpolation mode must be a string' );
      assert( any( strcmpi( value, {'xy','xz','yz'} ) ), '2D interpolation axes must be one of ''XY'', ''XZ'', or ''YZ''.' );
      try
        if strcmpi( value, 'xy' )
          prvImmCmd( this, 'e0' );
          this.interp2Daxes = 'XY';
        elseif strcmpi( value, 'xz' )
          prvImmCmd( this, 'e1' );
          this.interp2Daxes = 'XZ';
        elseif strcmpi( value, 'yz' )
          prvImmCmd(this, 'e2' );
          this.interp2Daxes = 'YZ';
        else
          error('Traverse:interp2Daxes:snbi','How did you manage to get this error?');
        end
      catch err
        if this.verbose; fprintf(1,'Error: %s\n%s\n',err.identifier,err.message'); end
        error('Traverse:Interp2DAxes:CantSet','Error setting the 2D interpolation axes');
      end
    end
    
    % Save method. Prevent saving of an open serial port
    function b = saveobj(this)
      if isconnected( this )
        warning('traverse:save:connected','You should not save a connected traverse object.');
        Disconnect( this );
      end
      b = this;
    end
    
    % Test whether the traverse is set up enough to perform a movement
    function movevalid( this )
      assert( isconnected( this ), 'Traverse must be connected.' );
      assert( ~isempty( this.maxV ) && ~isempty( this.resolution ), ...
          'Resolution and Max Velocity have not been set.' );
      assert( ~isempty( this.resolution ), 'Resolution has not been set.' );
      assert( ~isempty( this.maxV ), 'Max velocity has not been set.' );
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
      % Interpolation mode
      if this.interp3D
        fprintf(1,'3D interpolation is on.\n');
      else
        fprintf(1,'2D interpolation on axes %s.\n',this.interp2Daxes);
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