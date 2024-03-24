# What Workwork?

Workwork is a simple workspace management plugin for Neovim. It provides a very
basic interface for interating with files in multiple directories.

# Where Workwork?

Workwork has been tested so far in Neovim v0.9.5. If you tried it out on an
older version, please let me know whether it works so I can update either this
README or try fix any issues.

# Why Workwork?

There seems to be a lack of support for multi-directory/multi-repo, and that is
where Workwork comes in! 

At its core, workwork just manages the current
workspaces and the folders linked to them. That's is not so much right? The
catch is that by doing that, it allows for some pretty integrations with other
plugins, like Telescope. One could now browse through all the files included in
the multiple folders linked to the workspace, instead of a measly single
folder!

Ah, and if you are wondering about the name. It's a tribute to a, now old,RTS,
where some characters that could never stop saying "Work Work" whenever
they were ordered around. If you played it, you know what I mean. Me busy,
leave me alone!

# When Workwork?

The Full Roadmap still is TBD, but for now I plan to:

- [ ] Add git_files support for workspace with Telescope 
- [ ] Better manage your workspaces via a window
- [ ] Store current select workspace so it will be remembered and autoloaded at startup
- [ ] Integrate with session management plugins
- [ ] Integrate with dressing
- [ ] Support a default `finder` (right now fd or find)
- [ ] Support fzf-lua (this is a bit down the priority list, I didnt quite get how to have a good UX with its keymaps)
- [ ] ?

# How Workwork?

TBD




