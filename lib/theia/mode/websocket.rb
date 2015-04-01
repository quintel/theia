module Theia

  module Mode
    class Watcher < EventMachine::FileWatch
      # Public: Set the channel to which the watcher broadcasts changes.
      def self.channel=(channel)
        @@channel = channel
      end

      # Internal: File modified callback. Gets triggered whenever
      #           `data/state.yml` is changed.
      def file_modified
        broadcast_state
      end

      # Internal: Broadcasts the content of the state file, formatted as
      #           JSON.
      def broadcast_state
        detections = YAML.load_file(Theia.data_path_for('tag_detections.yml'))
        pieces = YAML.load_file(Theia.data_path_for('pieces.yml'))

        puts detections

        if detections == false
          print 'GOTCHA YOU LITTLE BUGGER!'
          tags = []
        else
          r1 = detections.values[0].values[0].values.flatten
          r2 = detections.values[0].values[1].values.flatten
          tags = r1 + r2
          tags = tags.uniq
        end

        state = { pieces: [] }

        # This method seems slightly more robust?
        tags.each do |t|
          pieces.each do |p|
            if t == p[:UID]
              state[:pieces] << p[:key]
            end
          end
        end

        #pieces.each do |p|
        #  if tags.include? p[:UID]
        #    state[:pieces] << p[:key]
        #  end
        #end

        @@channel.push(state.to_json)
      end
    end # Watcher

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
              puts "Subscribe: sid##{ sid.inspect }"

              ws.onclose do
                @channel.unsubscribe sid
                puts "Unsubscribe: sid##{ sid.inspect }"
              end
            end
          end

          EM.watch_file(Theia.data_path_for('tag_detections.yml'), Watcher)
          puts <<-MSG
Running on #{ @options[:host] || '0.0.0.0' }:#{ @options[:port] || 8080 }...
Press Ctrl+C to stop.
          MSG
        }
      end
    end # Websocket
  end # Mode

end # Theia
