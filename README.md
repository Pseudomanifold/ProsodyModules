# Prosody modules

This repository contains some modules for the [Prosody XMPP server](http://prosody.im). If not
mentioned otherwise, please do *not* assume that a module is ready for productive use.

## Installing the modules

Copy each `.lua` file that you wish to install to the `modules` directory of your Prosody installation.
Usually, this is a directory such as `/usr/lib/prosody/modules`. Ensure that the module has the same
permissions as the other modules. Edit the list of modules in the main configuration file of
Prosody (something like `/etc/prosody/prosody.cfg.lua`). For a module named `mod_foo.lua`, add an
entry `foo;` within the `modules_eanbled` list. Afterwards, restart the Prosody service.

## `mod_big_brother`

This module logs *all* messages of all users of the server and stores them in the data directory of
Prosody, e.g. `/var/lib/prosody`. At present, a subfolder named `logs` is created. Within this
folder, subfolders corresponding to the users of the server and their conversation partners will be
added. For each user, a daily log will be written.

Currently, the log format is very simple: `IN,user,message` for incoming messages, and
`OUT,user,message` for outgoing messages.

I would not recommend using the module *without* express permission of the users. I wanted a way of
archiving my messages on the server, possibly with the option of indexing and encrypting them later
on.
