__OVERVIEW__

| Project         | xpool
|:----------------|:--------------------------------------------------
| Homepage        | https://github.com/robgleeson/xpool
| Documentation   | http://rubydoc.info/github/robgleeson/xpool/frames 
| CI              | [![Build Status](https://travis-ci.org/robgleeson/xpool.png)](https://travis-ci.org/robgleeson/xpool)
| Author          | Rob Gleeson             


__DESCRIPTION__

xpool is a lightweight process pool. A pool manages a group of subprocesses
that are used when it is asked to dispatch a 'unit of work'. A 'unit of work' 
is defined as any object that implements the `run` method.

In order to send a 'unit of work' between processes each subprocess has its own
'message queue' that the pool writes to when it has been asked to schedule a 
unit of work. A unit of work is serialized(on write to queue), and 
deserialized(on read from queue). The serializer used under the hood is called 
[Marshal](http://rubydoc.info/stdlib/core/Marshal) and might be familiar to 
you already.

The logic for scheduling a unit of work is straightforward. A pool asks each 
and every subprocess under its control how frequently its message queue has 
been written to. The subprocess with the queue that has the least writes is told
to schedule the next unit of work. In practical terms this means if you have a 
pool with five subprocesses and schedule a unit of work five times, each 
subprocess in the pool would have executed the unit of work once.

A pool can become "dry" whenever all its subprocesses are busy. If you schedule
a unit of work on a dry pool the same scheduling logic applies but instead of
the unit of work executing right away it will be executed whenever the 
assigned subprocess is no longer busy. It is also possible to query the pool 
and ask if it is dry, but you can also ask an individual subprocess if it is
busy.

By default xpool will create a pool with X subprocesses, where X is the number 
of cores on your CPU. This seems like a reasonable default, but if you should 
decide to choose otherwise you can set the size of the pool when it is 
initialized. The pool can also be resized at runtime if you decide you need 
to scale up or down.

A unit of work may fail whenever an exception is left unhandled. When this 
happens xpool rescues the exception, marks the process as "failed", and 
re-raises the exception so that the failure can be seen. Finally, the process 
running the unit of work exits, and pool is down one process. A failed process 
can be restarted and interacted with, though, so it is possible to recover.

__EXAMPLES__

The examples don't demonstrate everything that xpool can do. The 
[API docs](http://rubydoc.info/github/robgleeson/xpool)
and 
[docs/](https://github.com/robgleeson/xpool/tree/master/docs)
directory cover the missing pieces.

_1._

A demo of how to schedule a unit of work: 

```ruby
#
# Make sure you define your units of work before
# you create a process pool or you'll get strange
# serialization errors.
#
class Unit
  def run
    sleep 1
  end
end
pool = XPool.new 2
pool.schedule Unit.new
pool.shutdown
```

_2._

A demo of how you can interact with subprocesses through 
[XPool::Process](http://rdoc.info/github/robgleeson/xpool/master/XPool/Process)
objects:

```ruby
class Unit
  def run
    sleep 1
  end
end
pool = XPool.new 2
subprocess = pool.schedule Unit.new 
p subprocess.busy? # => true
pool.shutdown
```

_3._

A demo of how to run a single unit of work across all subprocesses in the
pool:

```ruby
class Unit
  def run
    puts Process.pid
  end
end
pool = XPool.new 4
pool.broadcast Unit.new
pool.shutdown
```

__DEBUGGING OUTPUT__

xpool can print helpful debugging information if you set `XPool.debug` 
to true:

```ruby
XPool.debug = true
```

Or you can temporarily enable debugging output for the duration of a block:

```ruby
XPool.debug do 
  pool = XPool.new 2
  pool.shutdown
end
```

The debugging information you'll see is all about how the pool is operating. 
It can be interesting to look over even if you're not bug hunting.

__SIGUSR1__

All xpool managed subprocesses define a signal handler for the SIGUSR1 signal.
A unit of work should never define a signal handler for SIGUSR1 because that 
would overwrite the handler defined by xpool. SIGUSR2 is not caught by xpool
and it could be a good second option.


__INSTALL__

    $ gem install xpool

__LICENSE__

MIT. See `LICENSE.txt` 
