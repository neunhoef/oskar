# Oskar

This is a set of scripts and a container image to conveniently run
tests for ArangoDB on linux. It only needs the `fish` shell and `Docker`
installed on the system.

## Initial setup

Once you have cloned this repo or extracted the release or simply copied
the `helper.fish` script, the initial setup is as follows:

    cd oskar
    source helper.fish
    cloneArangoDB             (or cloneEnterprise if you have access)
    
This will pull the Docker image, start up a build and test container
and clone the ArangoDB source (optionally including the enterprise code)
into a subdirectory `work` in the current directory. It will also show
its current configuration.

## Choices for the tests

For the compilation, you can choose between maintainer mode switched on or
off. Use `maintainerOff` or `maintainerOn` to switch. Furthermore, you can
switch the build mode between `Debug` and `RelWithDebInfo`, use the commands
`debugMode` and `releaseMode`. Finally, if you have checked out the
enterprise code, you can switch between the community and enterprise
editions using `community` and `enterprise`. Use `parallelism <number>`
to specify which argument to `-j` should be used in the `make` stage,
the default is 64.

At runtime, you can choose the storage engine (use the `mmfiles` or
`rocksdb` command), and you can select a test suite. Use the `cluster`,
`single` or `resilience` command.

Finally, you can choose which branch or commit to use for the build
with the command

    switchBranches <REV_IN_MAIN_REPO> <REV_IN_ENTERPRISE_REPO>

## Building and testing

Build ArangoDB with the current build options by issueing

    buildArangoDB

and run the tests with the current runtime options using

    oskar

A report of the run will be shown on screen and a file with the current
timestamp will be put into the `work` directory.

## Cleaning up

To erase the build directories and checked out sources, use

    clearWorkDir

To stop the running build/test Docker container, use

    stopContainer

After that, essentially all resources used by oskar are freed again.
