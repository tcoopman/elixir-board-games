# BoardGames

## Development

* Install dependencies with `mix deps.get` and `npm install --prefix assets`
* run the database with `docker-compose up -d`
* Create and migrate your database with `mix do ecto.setup, event_store.create, event_store.init`
* Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### Reset the database

`mix do ecto.drop, ecto.setup, event_store.drop, event_store.create, event_store.init, initial_dev_data`

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
