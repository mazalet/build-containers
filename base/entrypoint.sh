#!/bin/bash

# Execute system setup hook
/systemsetup.sh

# If we are running docker natively, we want to create a user in the container
# with the same UID and GID as the user on the host machine, so that any files
# created are owned by that user. Without this they are all owned by root.
if [[ -n $BUILDER_UID ]] && [[ -n $BUILDER_GID ]]; then
    groupadd -o -g $BUILDER_GID $BUILDER_GROUP 2> /dev/null
    useradd -o -m -g $BUILDER_GID -u $BUILDER_UID $BUILDER_USER 2> /dev/null
    shopt -s dotglob

    # Make sure the home directory is owned by the specified user/group.
    chown -R $BUILDER_UID:$BUILDER_GID $HOME

    # Make sure build artifacts are accessible by the specified user/group.
    chown -R $BUILDER_UID:$BUILDER_GID /binary

    # Execute user setup hook
    chpst -u :$BUILDER_UID:$BUILDER_GID /usersetup.sh

    # Run the command as the specified user/group.
    exec chpst -u :$BUILDER_UID:$BUILDER_GID ctest -S entrypoint.cmake "$@"
else
    # Execute user setup hook
    /usersetup.sh

    # Just run the command as root.
    exec ctest -S entrypoint.cmake "$@"
fi
