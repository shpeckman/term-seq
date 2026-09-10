# src/seq/disposition.cr
struct Term::Seq::Disposition
  enum Kind : UInt8
    Pass
    Drop
    Replace
  end

  getter kind  : Kind
  getter bytes : Bytes

  def initialize(@kind : Kind, @bytes : Bytes = Bytes.empty)
  end

  PASS = Disposition.new(Kind::Pass)
  DROP = Disposition.new(Kind::Drop)

  def self.pass : Disposition
    PASS
  end

  def self.drop : Disposition
    DROP
  end

  def self.replace(bytes : Bytes) : Disposition
    new(Kind::Replace, bytes)
  end

  def self.replace(str : String) : Disposition
    new(Kind::Replace, str.to_slice)
  end
end
