__ABSTRACT__

A unit of work may fail whenever an exception is left unhandled. When this 
happens xpool rescues the exception, marks the process as "failed", and 
re-raises the exception so that the failure can be seen. Finally, the 
process running the unit of work exits, and pool is down one process. A failed 
process can be restarted and interacted with, though, so it is possible to 
recover.

__DETAILS__

A quick summary of the classes and methods that are most interesting when
interacting with failed processes:

  - [XPool#failed_processes](http://rubydoc.info/github/robgleeson/xpool/XPool#failed_processes-instance_method)  
  Returns an array of 
  [XPool::Process](http://rubydoc.info/github/robgleeson/xpool/XPool/Process)
  objects that are in a failed state.

  - [XPool::Process](http://rubydoc.info/github/robgleeson/xpool/XPool/Process)  
  Provides an object oriented interface on top of a subprocess in the pool.   
  The most interesting methods when a process is in a 'failed' state might be 
  [XPool::Process#restart](http://rubydoc.info/github/robgleeson/xpool/XPool/Process#restart-instance_method) 
  and
  [XPool::Process#backtrace](http://rubydoc.info/github/robgleeson/xpool/XPool/Process#backtrace-instance_method).

__EXAMPLES__

__1.__

```ruby
class Unit
  def run
    raise RuntimeError, "", []
  end
end

pool = XPool.new 2
pool.schedule Unit.new
sleep 0.05
pool.failed_processes.each(&:restart)
pool.shutdown
```
