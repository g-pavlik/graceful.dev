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
    end
  end
end

