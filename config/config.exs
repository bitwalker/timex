import Config

config :timex, Timex.Gettext, default_locale: "en"

if config_env() == :test do
  config :tzdata, :autoupdate, :disabled
end
