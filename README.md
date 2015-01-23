# gitmylab

Ruby command line application for managing gitlab objects.

Project syncing
---------------
creates a directory for each Group as its pathname.
It then clones every project in it's group directory. If the project is already cloned,
it updates the code (git pull).

## Prerequisites

- ruby version 1.9.3
- git