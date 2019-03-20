Bot
===

This is an experimental IRC bot written entirely in lua.

It exists almost exclusively to help me learn about the IRC protocol and to allow for quick prototyping before I actually dive in and code a bot in C.

PRs / Issues welcome, but note that, because this is a prototype, feature requests may be unlikely to be completed.

Setup
-----

You should have lua 5.3 installed as well as some additional lua libraries. These libraries can be installed using your operating system's package management or luarocks.

Required libraries
~~~~~~~~~~~~~~~~~~

* luafilesystem
* lsqlite3
* luasocket
* luajson
* luasec

Configuration
~~~~~~~~~~~~~

The configuration file is ``config.lua`` and should be updated before running the bot.

Starting the Bot
~~~~~~~~~~~~~~~~

In a terminal run the following command in the ``src`` directory:

.. code::

    lua main.lua

Support
-------

Bugs should be reported on the GitHub `issue tracker <https://github.com/HalosGhost/irc_bot/issues>`_.

License
-------

This codebase is licsensed under the `GNU General Public License v2.0 <http://www.gnu.org/licenses/gpl-2.0.html/>`_. All contributions should likewise be licensed the same.
