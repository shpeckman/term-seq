# src/seq/csi.cr
module Term::Seq
  struct Csi
    getter marker : UInt8
    getter final  : UInt8
    getter params : Slice(Int32)

    def initialize(@marker : UInt8, @final : UInt8, @params : Slice(Int32) = Slice(Int32).empty)
    end

    def marker_char : Char?
      @marker == 0_u8 ? nil : @marker.unsafe_chr
    end

    def final_char : Char
      @final.unsafe_chr
    end
  end

  struct Mode
    getter number      : Int32
    getter set         : Csi
    getter reset       : Csi
    getter set_bytes   : Bytes
    getter reset_bytes : Bytes

    def initialize(@number : Int32, @set : Csi, @reset : Csi,
                   @set_bytes : Bytes, @reset_bytes : Bytes)
    end

    def bytes(on : Bool) : Bytes
      on ? @set_bytes : @reset_bytes
    end
  end

  module Defs
  end
end
