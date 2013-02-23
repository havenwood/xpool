__OVERVIEW__

| Project         | XPool
|:----------------|:--------------------------------------------------
| Homepage        | https://github.com/robgleeson/xpool
| Documentation   | http://rubydoc.info/gems/xpool/frames 
| CI              | [![Build Status](https://travis-ci.org/robgleeson/xpool.png)](https://travis-ci.org/robgleeson/XPool)
| Author          | Rob Gleeson             


__DESCRIPTION__

XPool is a lightweight UNIX(X) Process Pool. The pool is dynamic in the sense
that you can resize the pool at runtime. The pool can be used to schedule 
'units of work' that are defined as any object that implements the 'run' 
method. A 'unit of work' is run by a dedicated subprocess in the pool but if 
the pool is dry(i.e: all subprocesses are busy executing work) the least busy
subprocess has the work put on its queue (each process has its own queue).

There are also all the other features you might expect, such as an interface to 
shutdown gracefully or to shutdown immediately. Graceful shutdowns can operate 
within a timeout that when passed shuts down the pool immediately. 


__EXAMPLES__

_1._

A demo of how you'd create a pool of 5 subprocesses:

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
pool = XPool.new 5
5.times { pool.schedule Unit.new }
pool.shutdown
```

_2._

A demo of how you'd resize the pool from 10 to 5 subprocesses at runtime:

```ruby
pool = XPool.new 10
pool.resize! 1..5
pool.shutdown
```
_3._

A demo of how you'd gracefully shutdown but force a hard shutdown if 3 seconds
pass by & all subprocesses have not exited:

```ruby
class Unit
  def run
    sleep 5
  end
end
pool = XPool.new 5
pool.schedule Unit.new
pool.shutdown 3
```

_4._

A demo of how you'd distribute a single unit of work to be run across all 
subprocesses in the pool:

```ruby
class Unit
  def run
    puts Process.pid
  end
end
pool = XPool.new 5
pool.broadcast Unit.new
pool.shutdown
```

__DEBUGGING OUTPUT__

XPool can print helpful debugging information if you set `XPool.debug` 
to true:

```ruby
XPool.debug = true
```

Or you can temporarily enable debugging output for the duration of a block:

```ruby
XPool.debug do 
  pool = XPool.new 5
  pool.shutdown
end
```

The debugging information you'll see is all about how the pool is operating. 
It can be interesting to look over even if you're not bug hunting.

__SIGUSR1__

All XPool managed subprocesses define a signal handler for the SIGUSR1 signal.
A unit of work should never define a signal handler for SIGUSR1 because that 
would overwrite the handler defined by XPool. SIGUSR2 might be a good second 
option because it is not used by XPool at all.

__INSTALL__

    $ gem install xpool

__LICENSE__

MIT. See `LICENSE.txt` 
