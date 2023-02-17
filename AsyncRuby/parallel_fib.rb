require 'thread'
require 'benchmark'

module FibSolver
  def self.fib(scheduler_queue, my_queue)
    loop do 
      scheduler_queue << [:ready, my_queue]
      message, *args = my_queue.pop
      case message
      when :fib
        n, client_queue = args
        client_queue << [:answer, n, fib_calc(n), my_queue]
      when :shutdown
        break 
      end
    end
  end

  def self.fib_calc(n)
    case n
    when 0, 1 then 1
    else fib_calc(n-1) + fib_calc(n-2)
    end
  end
end

module Scheduler
  def self.run(num_threads, mod, meth, to_calculate)
    my_queue = Queue.new
    threads = (1..num_threads).map {
      thread_queue = Queue.new
      thread = Thread.new do 
        mod.public_send(meth, my_queue, thread_queue)
        {thread: thread, queue: thread_queue}
      end
    }
    schedule_threads(threads, to_calculate, my_queue)
  end

  def self.schedule_threads(threads, to_calculate, my_queue)
    results = []
    loop do 
      message, *args = my_queue.pop
      case message
      when :ready
        thread_queue = args.first
        if to_calculate.size > 0
          next_job = to_calculate.shift
          thread_queue << [:fib, next_job, my_queue]
        else
          thread_queue << [:shutdown]
          if threads.size > 1
            threads.delete_if{|t| t[:queue] == thread_queue}
          else
            return results.sort{|r1, r2| r1[:number] <=> r2[:number]}
          end
        end
      when :answer
        number, result, _ = *args
        results << {number: number, result: result}
      end
    end
  end
end

to_process = [27, 33, 35, 11, 36, 29, 18, 37, 21, 31, 19, 10, 14, 30, 
             15, 17, 23, 28, 25, 34, 22, 20, 13, 16, 32, 12, 26, 24]

Benchmark.bm(3) do |b|
  (1..10).each do |num_threads| 
    b.report("#{num_threads}:") {
      Scheduler.run(num_threads, FibSolver, :fib, to_process.dup)
    }
  end
end

# rvm jruby do ruby paraller_fib.rb
