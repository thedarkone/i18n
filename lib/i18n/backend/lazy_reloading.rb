# Speeds up the reload! method (usefull in development mode) by first making sure
# the locale files have actually changed (this is done using their last mtime).
# Usage:
# 
#   I18n::Backend::Simple.send(:include, I18n::Backend::LazyReloading)

module I18n
  module Backend
    module LazyReloading
      def reload_with_mtime_check!
        if stale?
          reload_without_mtime_check!
          file_mtimes.clear
        end
      end
      
      def self.included(backend)
        backend.class_eval do
          alias_method :reload_without_mtime_check!, :reload!
          alias_method :reload!, :reload_with_mtime_check!

          alias_method :load_file_without_mtime_tracking, :load_file
          alias_method :load_file, :load_file_with_mtime_tracking
        end
      end
      
    protected
      def init_translations
        load_translations(*load_paths)
        @initialized = true
      end
      
      def load_paths
        I18n.load_path.flatten
      end
      
      def file_mtimes
        @file_mtimes ||= {}
      end
      
      def load_file_with_mtime_tracking(filename)
        load_file_without_mtime_tracking(filename)
        record_mtime_of(filename)
      end
      
      def record_mtime_of(filename)
        file_mtimes[filename] = File.mtime(filename)
      end

      def stale_translation_file?(filename)
        (mtime = file_mtimes[filename]).nil? || !File.file?(filename) || mtime < File.mtime(filename)
      end

      def stale?
        translation_path_removed? || translation_file_updated_or_added?
      end

      def translation_path_removed?
        (file_mtimes.keys - load_paths).any?
      end

      def translation_file_updated_or_added?
        load_paths.any? {|path| stale_translation_file?(path)}
      end
    end
  end
end