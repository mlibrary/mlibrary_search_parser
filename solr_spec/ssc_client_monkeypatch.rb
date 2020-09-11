require 'securerandom'

module SimpleSolrClient

  class Client

    # Set up files for a temp core
    def temp_core_dir_setup(corename)
      dest = Dir.mktmpdir("simple_solr_#{corename}_#{SecureRandom.uuid}", SOLR_INSTANCE_DIR)
      src  = SAMPLE_CORE_DIR
      FileUtils.cp_r File.join(src, '.'), dest
      dest
    end

  end

end