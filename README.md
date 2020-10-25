# MlibrarySearchParser

This is rough draft stuff, put in Github for backup more than
anything else. 


```
s = MLibraryParser::Search.new("my search string", config_hash)
query_object = s.solr_json_edismax
solr_params = query_object.params
json_payload = query_object.payload.to_json

```