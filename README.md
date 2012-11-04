__OVERVIEW__

| Project         | XPool
|:----------------|:--------------------------------------------------
| Homepage        | https://github.com/robgleeson/XPool
| Documentation   | http://rubydoc.info/gems/iprocess/frames 
| CI              | [![Build Status](https://travis-ci.org/robgleeson/XPool.png)](https://travis-ci.org/robgleeson/XPool)
| Author          | Rob Gleeson             


__DESCRIPTION__

Provides a UNIX Process Pool that can be used to schedule work. The pool can be 
dynamically resized at runtime as needs be, and if all subprocesses become busy
there is a queue that will be picked up as soon as a subprocess becomes
available. 


__EXAMPLES__

_1._

A demo of how you'd create a pool of subprocesses:

    #
    # Make sure you define your units of work before
    # you create a process pool or you'll get strange
    # serialization errors.
    #
    class Unit
      def call
        sleep(5)
      end
    end
    pool = XPool.new 10
    5.times { pool.schedule Unit.new }
    pool.shutdown

_2._

A demo of how you'd resize the pool at runtime:

    class Unit
      def call
        sleep 5
      end
    end
    pool = XPool.new 10
    pool.resize 1..5
    pool.shutdown

__INSTALL__

    $ gem install xpool

__LICENSE__

MIT. See `LICENSE.txt` 
