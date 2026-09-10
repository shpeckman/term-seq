# spec/csi_spec.cr
require "./spec_helper"

describe Term::Seq::Csi do
  it "exposes marker and final as characters" do
    csi = Term::Seq::Defs::MOUSE_SGR
    csi.marker_char.should eq('<')
    csi.final_char.should eq('M')
  end

  it "reports no marker as nil" do
    Term::Seq::Defs::HOME.marker_char.should be_nil
  end

  it "carries fixed params for static declarations" do
    Term::Seq::Defs::SGR_RESET.params.should eq(Slice[0])
  end

  it "leaves params empty for parameterized declarations" do
    Term::Seq::Defs::MOUSE_SGR.params.empty?.should be_true
    Term::Seq::Defs::CUP.params.empty?.should be_true
  end
end

describe Term::Seq::Mode do
  it "records the mode number" do
    Term::Seq::Defs::FOCUS_EVENTS.number.should eq(1004)
  end

  it "builds both directions from one declaration" do
    mode = Term::Seq::Defs::FOCUS_EVENTS
    String.new(mode.set_bytes).should eq("\e[?1004h")
    String.new(mode.reset_bytes).should eq("\e[?1004l")
  end

  it "selects bytes by direction" do
    mode = Term::Seq::Defs::ALT_SCREEN
    String.new(mode.bytes(true)).should eq("\e[?1049h")
    String.new(mode.bytes(false)).should eq("\e[?1049l")
  end

  it "describes each direction as a matchable csi" do
    mode = Term::Seq::Defs::BRACKETED_PASTE
    mode.set.marker_char.should eq('?')
    mode.set.final_char.should eq('h')
    mode.reset.final_char.should eq('l')
    mode.set.params.should eq(Slice[2004])
  end
end
