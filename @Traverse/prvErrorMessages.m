% Private function. Return a table of error messages
%
% v0.2.0 2015-04-17
%
% Copyright (c) 2014--2015, Zebb Prime
% Licence appended to source
function errmsg = prvErrorMessages( ~ )
% Error message table
  % code | message  |  throw an error?
  errmsg = {...
  '0',     'No Error', false;
  '1',     'Received a number that could not be interpreted correctly', true;
  '2',     'Limit switch hit. Step loss will have occured, you should perform a return to reference.', true;
  '3',     'Illegal axis specified', true;
  '4',     'No axes defined', true;
  '5',     'Syntax error', true;
  '6',     'End of memory (too many commands)', true;
  '7',     'Wrong number of parameters provided', true;
  '8',     'Command to be stored is not correct', true;
  'A',     'Pulse command out of range (1-6)', true;
  'B',     'Tell error', true;
  'C',     'CR character expected', true;
  'D',     'Illegal velocity', true;
  'E',     'Loop error', true;
  'F',     'Stopped by the user. Run Start to resume operation, or Abort to cancel.', true;
  'G',     'Invalid data field', true;
  'H',     'Command not permissable with open cover', true;
  '=',     'CR error---further commands expected', true;
  'R',     'A return to reference command must be executed first', true;
  };

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