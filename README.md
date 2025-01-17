(TODO: Write a better README. Current text is copied from [sidejob#1](https://github.com/basho/sidejob/pull/1))

![Sidejob OpenRiak Status](https://github.com/OpenRiak/sidejob/actions/workflows/erlang.yml/badge.svg?branch=openriak-3.2)

Note: this library was originally written to support process bounding in Riak using the sidejob_supervisor behavior. In Riak, this is used to limit the number of concurrent get/put FSMs that can be active, failing client requests with {error, overload} if the limit is ever hit. The purpose being to provide a fail-safe mechanism during extreme overload scenarios.

sidejob is an Erlang library that implements a parallel, capacity-limited request pool. In sidejob, these pools are called resources. A resource is managed by multiple gen_server like processes which can be sent calls and casts using sidejob:call or sidejob:cast respectively.

A resource has a fixed capacity. This capacity is split across all the workers, with each worker having a worker capacity of resource capacity/num_workers.

When sending a call/cast, sidejob dispatches the request to an available worker, where available means the worker has not reached it's designated limit. Each worker maintains a usage count in a per-resource public ETS table. The process that tries to send a request will read/update slots in this table to determine available workers.

This entire approach is implemented in a scalable manner. When a process tries to send a sidejob request, sidejob determines the Erlang scheduler id the process is running on, and uses that to pick a certain worker in the worker pool to try and send a request to. If that worker is at it's limit, the next worker in order is selected until all workers have been tried. Since multiple concurrent processes in Erlang will be running on different schedulers, and therefore start at different offsets in the worker list, multiple concurrent requests can be attempted with little lock contention. Specifically, different processes will be touching different slots in the ETS table and hitting different ETS segment locks.

For a normal sidejob worker, the limit corresponds to the size of a worker's mailbox. Before sending a request to a worker the relevant usage value is incremented by the sender, after receiving the message the worker decrements the usage value. Thus, the total number of messages that can be sent to a set of sidejob workers is limited; in other words, a bounded process mailbox.

However, sidejob workers can also implement custom usage strategies. For example, sidejob comes with the sidejob_supervisor worker that implements a parallel, capacity limited supervisor for dynamic, transient children. In this case, the capacity being managed is the number of spawned children. Trying to spawn additional results in the standard overload response from sidejob.

In addition to providing a capacity limit, the sidejob_supervisor behavior is more scalable than a single OTP supervisor when there multiple processes constantly attempting to start new children via said supervisor. This is because there are multiple parallel workers rather than a single gen_server process. For example, Riak moved away from using supervisors to manage it's get and put FSMs because the supervisor ended up being a bottleneck. Unfortunately, not using a supervisor made it hard to track the number of spawned children, return a list of child pids, etc. By moving to sidejob_supervisor for get/put FSM management, Riak can now how easily track FSM pids without the scalability problems -- in addition to having the ability to bound process growth.
