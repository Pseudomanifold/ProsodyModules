-- mod_big_brother.lua - A big brother logger for Prosody
-- 
-- Author:  Bastian Rieck <bastian@rieck.ru>
-- Licence: FreeBSD
--
-- Copyright (c) 2013, Bastian Rieck
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- Redistributions of source code must retain the above copyright notice, this
-- list of conditions and the following disclaimer.  Redistributions in binary
-- form must reproduce the above copyright notice, this list of conditions and the
-- following disclaimer in the documentation and/or other materials provided with
-- the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 

local jid_bare  = require "util.jid".bare;
local jid_split = require "util.jid".split;

local mkdir        = require "util.pposix".mkdir;
local data_manager = require "util.datamanager";
local prosody      = _G.prosody;

local function get_or_create_log_path( local_user, remote_user )

  -- TODO: This is ugly, but I don't know how to force mkdir to create
  -- complete paths.
  mkdir( prosody.paths[ "data" ] .. "/logs/" );
  mkdir( prosody.paths[ "data" ] .. "/logs/" .. local_user );
  mkdir( prosody.paths[ "data" ] .. "/logs/" .. local_user .. "/" .. remote_user );

  return( prosody.paths[ "data" ] .. "/logs/" .. local_user .. "/" .. remote_user ); 
end

local function get_log_filename()
  return( os.date( "%Y-%m-%d" ) .. ".txt" );
end

local function handle_incoming_message(event)
  local session      = event.origin;
  local stanza       = event.stanza;
  local message_type = stanza.attr.type;

  if message_type == "error" or message_type == "groupchat" then
    return;
  end

  local from = jid_bare( stanza.attr.from );
  local to   = jid_bare( stanza.attr.to );

  local message_body = stanza:get_child( "body" );

  if not message_body then
    return;
  end

  message_body = message_body:get_text();
  
  local username = session.username;
  local log_path = get_or_create_log_path( username, from );
  local log_name = get_log_filename();

  local f = io.open( log_path .. "/" .. log_name, "a+" );

  -- Force indent
  message_body = message_body:gsub( "\n", "\n" .. (( " " )):rep(#from+4) ); 
  f:write( "IN," .. from .. "," .. message_body .. "\n" );
  f:close();
end

local function handle_outgoing_message( event )

  local session      = event.origin;
  local stanza       = event.stanza;
  local message_type = stanza.attr.type;

  if message_type == "error" or message_type == "groupchat" then
    return;
  end

  local from = jid_bare( stanza.attr.from );
  local to   = jid_bare( stanza.attr.to );

  -- If messages are sent to self, they do not necessarily contain a "to"
  -- attribute.
  if not to then
    to = from;
  end

  local message_body = stanza:get_child( "body" );

  if not message_body then
    return;
  end

  message_body = message_body:get_text();
  
  local username = session.username;
  local log_path = get_or_create_log_path( username, to );
  local log_name = get_log_filename();

  local f = io.open( log_path .. "/" .. log_name, "a+" );

  -- Force indent
  message_body = message_body:gsub( "\n", "\n" .. (( " " )):rep(#to+5) ); 
  f:write( "OUT," .. to .. "," .. message_body .. "\n" );
  f:close();

end

module:hook("message/bare", handle_incoming_message, 1);
module:hook("message/full", handle_incoming_message, 1);

module:hook("pre-message/bare", handle_outgoing_message, 1);
module:hook("pre-message/full", handle_outgoing_message, 1);
module:hook("pre-message/host", handle_outgoing_message, 1);
