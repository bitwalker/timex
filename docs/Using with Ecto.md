# Using with Ecto

How to use Timex DateTimes with Ecto.

### Getting Started

Timex has can be integrated with Ecto via the `timex_ecto` plugin which is available on hex.pm:

```elixir
defp deps do
  [{:timex, "~> x.x.x"},
   {:timex_ecto, "~> x.x.x"}]
end
```

### Available Types

Timex-Ecto exposes a few different types for you to use:

- `Timex.Ecto.Date`: An ISO date (`YYYY-MM-DD`)
- `Timex.Ecto.Time`: An ISO time (`hh:mm:ss.sss`)
- `Timex.Ecto.DateTime`: An ISO 8601 datetime in UTC
- `Timex.Ecto.DateTimeWithTimezone`: Same as DateTime, but contains the timezone, i.e. `America/Chicago` as well. **NOTE** currently this is only supported with PostgreSQL, as it relies on complex types which are not currently supported in MySQL, and SQL Server user defined types require CLR types backing them which I have not explored in depth as of yet. See the section below titled [Using DateTimeWithTimezone](doc:using-with-ecto#section-using-datetimewithtimezone) for details.

### Model Definition

In order to use the Timex DateTime type instead of the Ecto DateTime type, your model should look something like the following:

```elixir
defmodule User do
  use Ecto.Model

  schema "users" do
    field :name, :string
    field :a_date,       Timex.Ecto.Date # Timex version of :date, will reify as a Date
    field :a_time,       Timex.Ecto.Time # Timex version of :time, will reify as a Time
    field :a_datetime,   Timex.Ecto.DateTime # Timex version of :datetime, will reify as a NaiveDateTime
    field :a_datetimetz, Timex.Ecto.DateTimeWithTimezone # A custom datatype (:datetimetz) implemented by Timex, will reify as a DateTime
  end
end
```

### Using Timex with Ecto's `timestamps` macro

Super simple! Your timestamps will now be `DateTime` structs instead of `Ecto.DateTime` structs.

```elixir
defmodule User do
  use Ecto.Model
  use Timex.Ecto.Timestamps

  schema "users" do
    field :name, :string
    timestamps
  end
end
```

### Using with Phoenix

Phoenix allows you to apply defaults globally to Ecto models via `web/web.ex` by changing the `model` function like so:

```elixir
def model do
  quote do
    use Ecto.Model
    use Timex.Ecto.Timestamps
  end
end
```

By doing this, you bring the Timex timestamps into scope in all your models.

### Using DateTimeWithTimezone

NOTE: This currently only applies to PostgreSQL.

You must run the following SQL against the database you plan on using this type with:

```sql
CREATE TYPE datetimetz AS (
    dt timestamptz,
    tz varchar
);
```

You can then use this type like so:

```sql
CREATE TABLE example (
  id integer,
  created_at datetimetz
);
```

That's it!

### Full Example

The following is a simple test app I built for vetting this plugin:

```elixir
defmodule EctoTest.Repo do
  use Ecto.Repo, otp_app: :timex_ecto_test
end

defmodule EctoTest.User do
  use Ecto.Model
  use Timex.Ecto.Timestamps

  schema "users" do
    field :name, :string
    field :date_test,       Timex.Ecto.Date
    field :time_test,       Timex.Ecto.Time
    field :datetime_test,   Timex.Ecto.DateTime
    field :datetimetz_test, Timex.Ecto.DateTimeWithTimezone
  end
end

defmodule EctoTest do
  import Ecto.Query
  use Timex

  alias EctoTest.User
  alias EctoTest.Repo

  def seed do
    time       = Time.now
    date       = Timex.today
    datetime   = Timex.now
    datetimetz = Timezone.convert(datetime, "Europe/Copenhagen")
    u = %User{name: "Paul", date_test: date, time_test: time, datetime_test: datetime, datetimetz_test: datetimetz}
    Repo.insert!(u)
  end

  def all do
    query = from u in User,
            select: u
    Repo.all(query)
  end
end

defmodule EctoTest.App do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    tree = [worker(EctoTest.Repo, [])]
    opts = [name: EctoTest.Sup, strategy: :one_for_one]
    Supervisor.start_link(tree, opts)
  end
end
```

And the results:

```elixir
iex(1)> EctoTest.seed

14:45:43.461 [debug] INSERT INTO "users" ("date_test", "datetime_test", "datetimetz_test", "name", "time_test") VALUES ($1, $2, $3, $4, $5) RETURNING "id" [{2015, 6, 25}, {{2015, 6, 25}, {19, 45, 43, 457000}}, {{{2015, 6, 25}, {21, 45, 43, 457000}}, "Europe/Copenhagen"}, "Paul", {19, 45, 43, 457000}] OK query=3.9ms
%EctoTest.User{__meta__: %Ecto.Schema.Metadata{source: "users",
  state: :loaded},
 date_test: ~D[2015-06-25],
 datetime_test: #<DateTime(2015-06-25T21:45:43.457Z Etc/UTC)>,
 datetimetz_test: #<DateTime(2015-06-25T21:45:43.457+02:00 Europe/Copenhagen)>,
 name: "Paul", time_test: #<Duration(P45Y6M6DT19H45M43.456856S)>
iex(2)> EctoTest.all

14:45:46.721 [debug] SELECT u0."id", u0."name", u0."date_test", u0."time_test", u0."datetime_test", u0."datetimetz_test" FROM "users" AS u0 [] OK query=0.7ms
[%EctoTest.User{__meta__: %Ecto.Schema.Metadata{source: "users",
   state: :loaded},
  date_test: ~D[2015-06-25],
  datetime_test: #<DateTime(2015-06-25T21:45:43.457Z Etc/UTC)>,
  datetimetz_test: #<DateTime(2015-06-25T21:45:43.457+02:00 Europe/Copenhagen)>,
  name: "Paul", time_test: #<Duration(P45Y6M6DT19H45M43.456856S)>}]
iex(3)>
```

And that's all there is to it!
