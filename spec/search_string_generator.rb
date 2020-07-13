require 'random-word'


def generate_quote_string(even)
  terms = []
  punc = [" ", "\""]
  words = RandomWord.nouns
  prng = Random.new

  length = prng.rand(10)

  (0..length).each do |n|
    terms.push(words.next.gsub(/_/, ' ') + ' ')
    quote = prng.rand(5) % 2
    if quote == 1
      terms.push("\"")
    end
  end
  q_count = terms.count("\"")
  if (even and q_count % 2 == 1) or (not even and q_count % 2 == 0)
    terms.push("\"")
  end

  terms.join(' ')
end
