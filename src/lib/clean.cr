# utilities to prevent malicious user input
module CrystalGauntlet::Clean
  extend self

  # for descriptions & similar
  def clean_special(str)
    str.gsub(/[\0]/, "")
  end

  # only allow alphanumeric chars & space
  def clean_char(str)
    str.gsub(/[^A-Za-z0-9 ]/, "")
  end

  # only allow "basic" characters (roughly printable ascii, excluding format-breaking chars)
  def clean_basic(str)
    str.gsub(/[^A-Za-z0-9\-_ ]/, "")
  end

  # only allows numbers
  def clean_number(str)
    str.gsub(/[^0-9]/, "")
  end

  # for b64 inputs; thoroughly cleans them
  def clean_b64(str)
    GDBase64.encode(GDBase64.decode_string(str))
  end
end
