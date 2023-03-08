require_relative 'sim'
require_relative 'test_sim'

if ARGV[0] == '-t'
  TestSim.new.run
else
  Sim.new.run
end
