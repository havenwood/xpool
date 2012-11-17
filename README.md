__OVERVIEW__

| Project         | XPool
|:----------------|:--------------------------------------------------
| Homepage        | https://github.com/robgleeson/xpool
| Documentation   | http://rubydoc.info/gems/xpool/frames 
| CI              | [![Build Status](https://travis-ci.org/robgleeson/XPool.png)](https://travis-ci.org/robgleeson/XPool)
| Author          | Rob Gleeson             


__DESCRIPTION__

A lightweight and fast UNIX(X) Process Pool implementation. The size of the pool
is dynamic and it can be resized at runtime if needs be. It also has everything
else you might expect: a way to shutdown gracefully or not so gracefully, 
graceful shutdowns that time out, & a way to schedule work ('work' is any 
object that implements `.run`). When the pool becomes busy the work is left on
a queue and the next available subprocess will come & take it(also as you might
expect).

__EXAMPLES__

_1._

A demo of how you'd create a pool of 10 subprocesses:

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
    pool = XPool.new 10
    5.times { pool.schedule Unit.new }
    pool.shutdown

_2._

A demo of how you'd resize the pool from 10 to 5 subprocesses at runtime:

    class Unit
      def call
        sleep 5
      end
    end
    pool = XPool.new 10
    pool.resize 1..5
    pool.shutdown

_3._

A demo of how you'd gracefully shutdown but force a hard shutdown if 3 seconds
pass by & all subprocesses have not exited:

    class Unit
      def call
        sleep 5
      end
    end
    pool = XPool.new 10
    pool.schedule Unit.new
    pool.shutdown 3

__INSTALL__

    $ gem install xpool

__LICENSE__

MIT. See `LICENSE.txt` 
