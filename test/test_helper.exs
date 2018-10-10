# Ensure tzdata is up to date
{:ok, _} = Application.ensure_all_started(:tzdata)
Application.ensure_all_started(:stream_data)
_ = Tzdata.ReleaseUpdater.poll_for_update()
ExUnit.configure(exclude: [skip: true])
ExUnit.start()
