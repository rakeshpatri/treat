module Treat
  module Group
    # Modify the extended class.
    def self.extended(group)
      group.module_eval do
        class << self
          attr_accessor :type, :default, :targets
          attr_accessor :presets, :preprocessors, :decorators
        end
        self.presets = {}
        self.preprocessors = {}
        self.decorators = {}
        # Return the method corresponding to the group.
        # This method resolves the name of the method
        # that a group should provide based on the name
        # of the group. Basically, if the group ends in
        # -ers, the verb corresponding to the group is
        # returned (tokenizers -> tokenize, inflectors ->
        # inflect). Otherwise, the name of the method
        # is the same as that of the group (encoding ->
        # encoding, tag -> tag).
        @method = nil
        def self.method
          return @method if @method
          m = ucc(cl(self))
          if m[-3..-1] == 'ers'
            if ['k', 't', 'm', 'd', 'g', 'n'].include? m[-4]
              n = m[0..-4]
              n = n[0..-2] if n[-1] == n[-2]
            else
              n = m[0..-3]
            end
          elsif m[-3..-1] == 'ors'
            n = m[0..-4] + 'e'
          else
            n = m
          end
          @method = n.intern
        end
      end
      group.list
    end
    # Create a new algorithm within the group. Once
    # the algorithm is added, it will be automatically
    # installed on all the targets of the group.
    def add(class_name, &block)
      klass = self.const_set(cc(class_name).intern, Class.new)
      method = self.method
      @@list[ucc(cl(self))] << class_name
      klass.send(:define_singleton_method, method) do |entity, options={}|
        block.call(entity, options)
      end
    end
    # Boolean - does the group have the supplied class
    # included in its targets?
    def has_target?(target, strict = false)
      is_target = false
      self.targets.each do |entity_type|
        entity_type = Entities.const_get(cc(entity_type))
        if target < entity_type || entity_type == target
          is_target = true; break
        end
      end
      is_target
    end
    # Cache the list of adaptors to improve performance.
    @@list = {}
    # Populates once the list of the adaptors in the group
    # by crawling the filesystem.
    def list
      mod = ucc(cl(self))
      if @@list[mod].nil?
        @@list[mod] = []
        dirs = Dir.glob("#{Treat.lib}/treat/*/#{mod}/*.rb")
        dirs.each do |file|
          @@list[mod] <<
          file.split('/')[-1][0..-4].intern
        end
      end
      @@list[mod]
    end
    # Get constants in this module, excluding those
    # defined by parent modules.
    def const_get(const); super(const, false); end
    # Lazy load the classes in the group.
    def const_missing(const)
      bits = self.ancestors[0].to_s.split('::')
      bits.collect! { |bit| ucc(bit) }
      file = bits.join('/') + "/#{ucc(const)}"
      if not File.readable?("#{Treat.lib}/#{file}.rb")
        raise Treat::Exception,
        "File '#{file}.rb' corresponding to requested delegate "+
        "#{self}::#{const} does not exist."
      else
        require file
        if not const_defined?(const)
          raise Treat::Exception,
          "File #{file} does not define #{self}::#{const}."
        end
        const_get(const)
      end
    end
  end
end
