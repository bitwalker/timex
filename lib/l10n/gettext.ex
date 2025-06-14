defmodule Timex.Gettext do
  use Gettext.Backend, otp_app: :timex, priv: "priv/translations"
end
