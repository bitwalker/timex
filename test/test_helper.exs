{:ok, _} = Application.ensure_all_started(:tzdata)
Application.ensure_all_started(:stream_data)
ExUnit.configure(exclude: [skip: true, tzdata_update: true])
ExUnit.start()
