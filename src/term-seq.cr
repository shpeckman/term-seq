# src/term-seq.cr
require "./seq/buffer"
require "./seq/csi"
require "./seq/emitter"
require "./seq/disposition"
require "./seq/token"
require "./seq/filtering"
require "./seq/input_filter"
require "./seq/output_filter"

module Term::Seq
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}
end
