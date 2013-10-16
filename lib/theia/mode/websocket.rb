require 'yajl/json_gem'
require 'eventmachine'

module Theia
  module Mode
    class Watcher < EventMachine::FileWatch
      def self.channel=(channel)
        @@channel = channel
      end

      def file_modified
        broadcast_state
      end

      def broadcast_state
        state = YAML.load_file(Theia.data_path_for('state.yml'))
        @@channel.push(state.to_json)
      end
    end

    class Websocket < Base
      attr_accessor :channel

      def initialize(options)
        super(options)

        @channel = EM::Channel.new
        Watcher.channel = @channel
      end

      def start
        # Makes for more efficient file watching on OS X
        EventMachine.kqueue = EventMachine.kqueue?

        EM.run {
          EM::WebSocket.run(host: @options[:host] || '0.0.0.0', port: @options[:port] || 8080) do |ws|
            ws.onopen do
              sid = @channel.subscribe { |msg| ws.send msg }

              ws.onclose do
                @channel.unsubscribe sid
              end
            end
          end

          EM.watch_file(Theia.data_path_for('state.yml'), Watcher)
          puts <<-MSG
Running on #{ @options[:host] || '0.0.0.0' }:#{ @options[:port] || 8080 }...
Press Ctrl+C to stop.
          MSG
        }
      end
    end
  end
end
