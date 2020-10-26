require 'pry'
require 'simple_solr_client'
require 'mlibrary_search_parser'
require 'erb'

@config_file = './spec/data/00-catalog.yml'
@config = YAML.load(ERB.new(File.read(@config_file)).result)


# Your solr port (local) or full URL (remote)
portOrURL = 'http://julep-1.umdl.umich.edu:8026/solr'
# portOrURL = 9639
client = SimpleSolrClient::Client.new(portOrURL)
@core = client.core(client.cores.first)

# Other solr params
#
@solr_params = {
    fl: 'id,title,mainauthor',
    rows: 10
}

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
# Override solr parms in kwargs
def get(str, **kwargs)
  resp = get_respose(str, **kwargs)
  resp['response']['docs']
end

# In case we need to look at the whole response
def get_respose(str, **kwargs)
  s = search(str)
  params = lp(s).params.merge(@solr_params).merge(kwargs)
  @core.get('select', params)
end
