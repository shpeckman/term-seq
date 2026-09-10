# src/term-seq.cr
require "./filter"
require "./emitter"

module Term::Seq
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}
end
