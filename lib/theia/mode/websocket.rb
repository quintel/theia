require 'yajl/json_gem'

module Theia
  module Mode
    class Watcher < EventMachine::FileWatch
      def initialize(path, channel)
        @path     = path
        @channel  = channel
      end

      def file_modified
        broadcast_state
      end

      def broadcast_state
        state = YAML.load_file("#{ data_path }")
        @channel.push(state.to_json)
      end
    end

    class Websocket < Base
      attr_accessor :channel

      def initialize(options)
        super(options)

        @channel = EM::Channel.new
        @watcher = Watcher.new(data_path, @channel)
      end

      def start
        # Makes for more efficient file watching on OS X
        EventMachine.kqueue = EventMachine.kqueue?

        EM.run {
          EM::WebSocket.run(host: @@options[:host] || '0.0.0.0', port: @@options[:port] || 8080) do |ws|
            ws.onopen do
              sid = @channel.subscribe { |msg| ws.send msg }

              ws.onclose do
                @channel.unsubscribe sid
              end
            end
          end

          EM.watch_file("#{ data_path }/state.yml", Watcher.new(data_path, @channel))
          puts <<-MSG
Running on #{ @@options[:host] || '0.0.0.0' }:#{ @@options[:port] || 8080 }...
Press Ctrl+C to stop.
          MSG
        }
      end
    end
  end
end
