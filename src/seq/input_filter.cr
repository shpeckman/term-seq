# src/seq/input_filter.cr
class Term::Seq::InputFilter
  include Filtering

  getter? paste : Bool = false

  @paste_handler : Handler? = nil
  @pass_next     : Bool     = false
  @esc_ticks     : Int32    = 0

  def initialize(@escape_ticks : Int32 = 2)
  end

  def on_paste(&handler : Handler) : self
    @paste_handler = handler
    self
  end

  def pass_next! : Nil
    @pass_next = true
  end

  def tick : Bytes
    unless @carry_size == 1 && @carry.to_unsafe[@carry_off] == ESC
      @esc_ticks = 0
      return Bytes.empty
    end
    @esc_ticks += 1
    return Bytes.empty if @esc_ticks < @escape_ticks

    @esc_ticks  = 0
    @out_size   = 0
    @copying    = true
    @passed     = 0
    span        = @carry[@carry_off, 1]
    @src        = span
    @carry_size = 0
    apply(Token.new(Token::Kind::Literal, span), @byte_rules.unsafe_fetch(ESC)) unless guarded?(span)
    @src = Bytes.empty
    @out[0, @out_size]
  end

  protected def note_feed : Nil
    @esc_ticks = 0
  end

  protected def bypass?(chunk : Bytes) : Bool
    return false if @pass_next
    return false if chunk.index(ESC)
    @paste ? @paste_handler.nil? : @byte_rule_count == 0
  end

  protected def paste_marker?(span : Bytes, final : UInt8, marker : UInt8, groups : Int32, values : Int32) : Bool
    return false unless final == 0x7E_u8 && marker == 0_u8 && groups == 1 && values == 1
    case @params_buf[0]
    when 200
      return false if @paste
      @paste = true
      emit_paste(Token::Kind::PasteStart, span)
      true
    when 201
      return false unless @paste
      @paste = false
      emit_paste(Token::Kind::PasteEnd, span)
      true
    else
      false
    end
  end

  protected def guarded?(span : Bytes) : Bool
    if @paste
      emit_paste(Token::Kind::PasteData, span)
      return true
    end
    if @pass_next
      @pass_next = false
      emit_span(span)
      return true
    end
    false
  end

  protected def literal_guarded?(run : Bytes) : Bool
    return false unless @paste
    emit_paste(Token::Kind::PasteData, run)
    true
  end

  protected def plain_literal(run : Bytes) : Nil
    @pass_next = false
    emit_span(run)
  end

  protected def forward_pending(run : Bytes, at : Int32) : Int32
    return at unless @pass_next && at < run.size
    @pass_next = false
    emit_span(run[at, 1])
    at + 1
  end

  private def emit_paste(kind : Token::Kind, span : Bytes) : Nil
    if handler = @paste_handler
      apply(Token.new(kind, span), handler)
    else
      emit_span(span)
    end
  end
end
