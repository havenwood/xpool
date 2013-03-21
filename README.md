__OVERVIEW__

| Project         | xpool
|:----------------|:--------------------------------------------------
| Homepage        | https://github.com/robgleeson/xpool
| Documentation   | http://rubydoc.info/github/robgleeson/xpool/frames 
| CI              | [![Build Status](https://travis-ci.org/robgleeson/xpool.png)](https://travis-ci.org/robgleeson/xpool)
| Author          | Rob Gleeson             


__DESCRIPTION__

xpool is a lightweight process pool. The pool manages a group of subprocesses
that are used when the pool is asked to dispatch a 'unit of work'. A 
'unit of work' is defined as any object that implements the `run` method.

All subprocesses in the pool have their own message queue that the pool places
work onto according to a very simple algorithm: the subprocess who has scheduled
the least amount of work is the subprocess who is asked to put the work on its
queue. This helps ensure an even distribution of work among all subprocesses in 
the pool. The message queue that each subprocess has is also what ensures 
work can be queued when the pool becomes dry (all subprocesses are busy). 

Incase a unit of work raises an exception that it does not handle xpool will
rescue the exception and mark the process as 'failed'. A failed process can be
restarted, and it is also possible to access the backtrace of a failed process 
through `XPool` and `XPool::Process` objects. The exception is also re-raised 
so that you can see a process has failed from the output ruby prints when an 
exception is left unhandled.

__POOL SIZE__

By default xpool will create a pool with X subprocesses, where X is the number 
of cores on your CPU. This seems like a reasonable default, but if you should 
decide to choose otherwise you can set the size of the pool when it is 
initialized. The pool can also be resized at runtime if you decide you need to 
scale up or down.

__EXAMPLES__

The examples don't demonstrate everything that xpool can do. The 
[API docs](http://rubydoc.info/github/robgleeson/xpool) 
cover the missing pieces.

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
