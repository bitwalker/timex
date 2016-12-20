# Ensure tzdata is up to date
{:ok, _} = Application.ensure_all_started(:tzdata)
_ = Tzdata.ReleaseUpdater.poll_for_update()
ExUnit.configure(exclude: [skip: true])
ExUnit.start()
