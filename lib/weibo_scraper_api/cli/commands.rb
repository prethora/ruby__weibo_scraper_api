Dir[File.join(__dir__,"commands","**","*.rb")].each {|l| require l}