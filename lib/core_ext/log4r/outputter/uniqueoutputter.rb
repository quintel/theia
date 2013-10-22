module Log4r
  # Class which prevents duplicate output to end up in the console. This considerably
  # quiets down the debugging messages we get (especially the ones pertaining the map
  # errors.)
  class UniqueOutputter < IOOutputter
    def initialize(_name, hash={})
      super(_name, $stdout, hash)

      @_last_message = ''
    end

    #######
    private
    #######

    def write(data)
      return if @_last_message == data

      @_last_message = data
      super
    end
  end
end
