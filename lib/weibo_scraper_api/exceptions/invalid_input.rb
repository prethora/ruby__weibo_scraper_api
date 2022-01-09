class WSAPI
    module Exceptions
        class InvalidInput < StandardError
            def initialize(code,info = "none")
                super("unexpected error: #{code}; info: #{info}")
            end
        end
    end
end