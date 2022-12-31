# utilities to prevent malicious user input
module CrystalGauntlet::Clean
  extend self

  # removes commonly used chars in response formatting
  def clean_special(str)
    # these are just the ones commonly used in response formatting
    # i'm unsure if any other ones should be added, so for the time
    # being i'll just keep it as is
    str.gsub(/[:\|~#\(\)\0\n~]/, "")
  end

  # for descriptions & similar
  def clean_special_lenient(str)
    str.gsub(/[\0]/, "")
  end

  # only allow alphanumeric chars & space
  def clean_char(str)
    str.gsub(/[^A-Za-z0-9 ]/, "")
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
