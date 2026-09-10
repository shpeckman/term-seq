# src/seq/token.cr
struct Term::Seq::Token
  enum Kind : UInt8
    Literal
    Escape
    Csi
    Ss3
    StringSeq
    Osc
    Dcs
    Apc
    PasteStart
    PasteData
    PasteEnd
  end

  ABSENT    = -1
  ACCUM_MAX = (Int32::MAX - 9) // 10

  getter kind   : Kind
  getter bytes  : Bytes
  getter marker : UInt8
  getter final  : UInt8
  getter params : Slice(Int32)
  getter starts : Slice(Int32)

  def initialize(@kind : Kind, @bytes : Bytes, @marker : UInt8 = 0_u8, @final : UInt8 = 0_u8,
                 @params : Slice(Int32) = Slice(Int32).empty,
                 @starts : Slice(Int32) = Slice(Int32).empty)
  end

  def byte : UInt8
    @bytes[0]
  end

  def set? : Bool
    @final == 0x68_u8
  end

  def groups : Int32
    @starts.size > 1 ? @starts.size - 1 : 0
  end

  def sub_count(group : Int32) : Int32
    return 0 if group < 0 || group >= groups
    @starts.unsafe_fetch(group + 1) - @starts.unsafe_fetch(group)
  end

  def sub?(group : Int32, index : Int32) : Int32?
    return nil if index < 0 || group < 0 || group >= groups
    at = @starts.unsafe_fetch(group) + index
    return nil if at >= @starts.unsafe_fetch(group + 1)
    value = @params.unsafe_fetch(at)
    value == ABSENT ? nil : value
  end

  def sub(group : Int32, index : Int32, default : Int32 = 0) : Int32
    sub?(group, index) || default
  end

  def param?(group : Int32) : Int32?
    sub?(group, 0)
  end

  def param(group : Int32, default : Int32 = 0) : Int32
    sub?(group, 0) || default
  end

  def copy : Bytes
    span = Bytes.new(@bytes.size)
    @bytes.copy_to(span)
    span
  end

  def content : Bytes
    case @kind
    when .string_seq?, .osc?, .apc?
      string_content(2)
    when .dcs?
      string_content(dcs_content_start)
    else
      @bytes
    end
  end

  def osc_code : Int32?
    return nil unless @kind.osc?
    value = 0
    seen  = false
    content.each do |b|
      break if b == 0x3B_u8
      return nil if b < 0x30_u8 || b > 0x39_u8
      value = value * 10 + (b - 0x30_u8).to_i32 if value <= ACCUM_MAX
      seen  = true
    end
    seen ? value : nil
  end

  private def string_content(start : Int32) : Bytes
    stop = @bytes.size
    if @bytes[stop - 1] == 0x07_u8
      stop -= 1
    elsif stop >= 2 && @bytes[stop - 2] == 0x1B_u8 && @bytes[stop - 1] == 0x5C_u8
      stop -= 2
    end
    stop > start ? @bytes[start, stop - start] : Bytes.empty
  end

  private def dcs_content_start : Int32
    i    = 2
    size = @bytes.size
    while i < size && @bytes[i] >= 0x30_u8 && @bytes[i] <= 0x3F_u8
      i += 1
    end
    while i < size && @bytes[i] >= 0x20_u8 && @bytes[i] <= 0x2F_u8
      i += 1
    end
    i += 1 if i < size && @bytes[i] >= 0x40_u8 && @bytes[i] <= 0x7E_u8
    i
  end

  def to_s(io : IO) : Nil
    io.write(@bytes)
  end
end
