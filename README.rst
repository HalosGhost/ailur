Bot
===

This is an experimental IRC bot written entirely in lua.

It exists almost exclusively to help me learn about the IRC protocol and to allow for quick prototyping before I actually dive in and code a bot in C.

PRs / Issues welcome, but note that, because this is a prototype, feature requests may be unlikely to be completed.

Lua libraries used
------------------

* luafilesystem
* lsqlite3
* luasocket
* luajson
* luasec

Configure and Run
-----------------

The configuration file is `config.lua` and should be updated before running the
bot. To start the bot run:

.. code:: bash

    lua main.lua
