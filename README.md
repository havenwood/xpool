__OVERVIEW__

| Project         | XPool
|:----------------|:--------------------------------------------------
| Homepage        | https://github.com/robgleeson/xpool
| Documentation   | http://rubydoc.info/gems/xpool/frames 
| CI              | [![Build Status](https://travis-ci.org/robgleeson/XPool.png)](https://travis-ci.org/robgleeson/XPool)
| Author          | Rob Gleeson             


__DESCRIPTION__

A lightweight UNIX(X) Process Pool implementation. The size of the pool
is dynamic and it can be resized at runtime if needs be. 'Units of work' are
what you can schedule and each unit of work is dispatched by a free subprocess 
in the the pool. If the pool dries up(all subprocesses are busy) the units 
of work are queued & the next available subprocess will pick it up.

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
class Unit
  def run
    sleep 5
  end
end
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

__INSTALL__

    $ gem install xpool

__LICENSE__

MIT. See `LICENSE.txt` 
