defmodule Timex.Gettext do
  # One module per locale lets Gettext compile the locales in parallel,
  # instead of one large module that the rest of the package waits on.
  use Gettext.Backend, otp_app: :timex, priv: "priv/translations", split_module_by: [:locale]
end
