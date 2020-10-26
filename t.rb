require 'pry'
require 'simple_solr_client'
require 'mlibrary_search_parser'
require 'erb'

@config_file = './spec/data/00-catalog.yml'
@config = YAML.load(ERB.new(File.read(@config_file)).result)


# Your solr port
port = 9639
client = SimpleSolrClient::Client.new(port)
@core = client.core(client.cores.first)

# Index a document, translating title to title_common and
# setting a random id if needed and the allfields

def index(h)
  h[:allfields] = h.values.join(" ")
  h[:id] ||= Random.rand(100000)
  h[:title_common] = h[:title] if h.has_key? :title
  @core.add_docs(h).commit
end

# build a search object
def search(str)
  MLibrarySearchParser::Search.new(str, @config)
end

# build a local_params object
def lp(s)
  MLibrarySearchParser::Transformer::Solr::LocalParams.new(s)
end

# Make the solr call with the localparams and get the docs
def get(str)
  resp = get_respose(str)
  resp['response']['docs']
end

# In case we need to look at the whole response
def get_respose(str)
  s = search(str)
  params = lp(s).params
  @core.get('select', params)
end
