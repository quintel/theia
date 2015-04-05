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

        offshore = %w(Antenna0 Antenna1 Antenna2 Antenna3 Antenna4 Antenna6)

        detections = YAML.load_file(Theia.data_path_for('tag_detections.yml'))
        pieces = YAML.load_file(Theia.data_path_for('pieces.yml'))
        # pieces = pieces.map{ |p| p[:UID].flatten }

        if detections == false
          puts 'Bad data read/write - no updates'
        else
          r1 = detections.values[0].values[0].values.flatten
          r2 = detections.values[0].values[1].values.flatten
          tags = (r1 + r2).uniq

          state = { pieces: [] }

          pieces.each do |p|
            (tags & p[:UID]).each do |t|
              if p[:key] == 'wind_turbine'
                if offshore.include? detections.values[0].values[0].key([t])
                  state[:pieces] << "wind_turbine_offshore"
                else
                  state[:pieces] << "wind_turbine_inland"
                end
              else
                state[:pieces] << p[:key]
              end
            end
          end

          puts "Pieces: #{ state[:pieces] }"
          @@channel.push(state.to_json)
        end
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
