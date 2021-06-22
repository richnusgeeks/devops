This is a dev ready CRUD API created in Go Echo Web Framework. The Go was
chosen here over other Dynamic languages like Ruby/Python etc. because:

- Go is statically typed which means better type checking and security

- Go is natively compiled and highly performant vs the dynamic languages
  which don't perform n scale well due to layers of abstractions, bytecode
  interpretation, global interpreter lock etc.

- Go produces statically linked binaries which are drop and run. This solves
  a number of operational, parity and dependencies issues

- Many more ...

Components:

- API server (accessible on localhost:58080)

- Postgres backend 

- Adminer for GUI based db management (accessible on localhost:48080, user/pswrd/db postgres)

- CRUD enpoints unit testing

- cAdvisor for the resource usage and performance characteristics of the
  running containers (accessible on localhost:38080)

- TBA ...

Runbook (on GNU/Linux, macOS):

- [Install Docker for your OS](https://docs.docker.com/get-docker/) and
  [configure the docker cli to run under your current user without sudo](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user)

- [Download docker-compose and drop in a location in your PATH](https://docs.docker.com/compose/install/)

- Execute `./create_webapp_crudtest_stack.sh up` to build necessary docker
  images and bringup the whole stack

- You could execute `./create_webapp_crudtest_stack.sh buildup` to rebuild the
  docker images to capture new changes and bringup the whole stack

- Execute `./create_webapp_crudtest_stack.sh ps` to dump the running stack
  details

- Execute `./create_webapp_crudtest_stack.sh logs` to dump the logs for the
  entire stack (grep for the desired component e.g. ... | grep wacrudtstbnch)

- Execute `./create_webapp_crudtest_stack.sh down` to bring down the running 
  stack

- Execute `./create_webapp_crudtest_stack.sh cleandown` to bringdown the stack
  and cleanup the resources

- You could execute `./create_webapp_crudtest_stack.sh` to see all options
  provided by the driver script

PS: This whole solution is assembled (API server created from scratch) in few
    hours reusing various pieces present in the toplevel github repo.
