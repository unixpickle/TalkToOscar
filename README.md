TalkToOscar
===========

IMPORTANT: I have rewritten an OSCAR library from the ground up.  The new library, known as LibOrange, can be accessed at: https://github.com/unixpickle/LibOrange

This is a basic AOL Instant Messenger API for anything with Cocoa/Foundation, and an Objective-C compiler.  It has not been tested on the iPhone, but it is relatively assumed that it will work.  IMs are sent through an IM sender class, which encloses the main session class.  Events such as incoming IMs, buddy art, and everything else is done by a session manager object, which contains multiple other manager objects for various tasks.

The feedbag manager is responsible for managing and updating the buddy list, and can be accessed with [sessionHandler feedbagHandler].  The structure of most things in this library is heavily Object Oriented, which is considered a positive thing by most.

Usage
=====

This is a sample which accepts IM commands.  These commands are:

    add buddyname      # add buddy to the Buddies group
    remove buddyname   # remove buddy from the Buddies group
    addgroup group     # add a group if it does not exist already
    removegroup group  # remove a group if it does exist
    block username     # blocks a buddy or user
    unblock username   # unblocks a buddy or user
    buddylist          # prints out the buddy list
    takeicon           # mirror the icon of the sender (if it is available)
    setstatus message  # set the status message

When a command is run, the bot will reply with a message such as "Why do you say %s", where %s is the original message/command.

Using this Library
==================

You are permitted to use this library in any application, change it however you need, and distribute your changes for money.  There is no licensing over this library.  There is also no warranty, although I will assist you if you ask me.

Contact the Developer
=====================

This library was programmed by Alex Nichol, a 14-year-old iPhone, Linux, and Mac developer.  My AIM is alexqnichol@aim.com, my email address is alexnichol@comcast.net.

