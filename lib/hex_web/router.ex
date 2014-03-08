defmodule HexWeb.Router do
  use Plug.Router
  import Plug.Connection
  import HexWeb.Router.Util
  alias HexWeb.Plugs
  alias HexWeb.RegistryBuilder
  alias HexWeb.Config

  plug :fetch
  plug Plugs.Exception
  plug Plugs.Forwarded
  plug Plugs.Redirect, ssl: &Config.use_ssl/0, redirect: [&Config.app_host/0], to: &Config.url/0
  plug Plug.MethodOverride
  plug :match
  plug :dispatch


  get "api/registry" do
    # TODO: Remove dets here when most people use updated client (2014-02-25)
    conn = Plugs.Accept.call(conn, vendor: "hex", allow: ["dets", "ets"])
    send_file(conn, 200, RegistryBuilder.latest_file)
  end

  get "installs" do
    body = [
      dev: [
        version: "0.0.1-dev",
        url: "http://storage.hex.pm/installs/hex.ez" ] ]

    conn
    |> Plug.Parsers.call(parsers: [HexWeb.Parsers.Json, HexWeb.Parsers.Elixir])
    |> Plugs.Accept.call(vendor: "hex", allow: [{"application","json"}, "json", "elixir"])
    |> Plugs.Version.call([])
    |> send_render(200, body)
  end

  forward "/api", HexWeb.Router.API

  match _ do
    send_resp(conn, 404, "")
  end

  defp fetch(conn, _opts) do
    # Should this be in Plug.MethodOverride ?
    fetch_params(conn)
  end
end
