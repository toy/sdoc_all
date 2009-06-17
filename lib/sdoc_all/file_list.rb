class SdocAll
  class FileList < Rake::FileList
    def resolve
      if @pending
        super
        @items.replace(@items.uniq.reject{ |path| !File.exist?(path) })
      end
      self
    end
  end
end
