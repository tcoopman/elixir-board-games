defmodule BoardGamesWeb.PageLiveTest do
  use BoardGamesWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Create a new game"
    assert render(page_live) =~ "Create a new game"
  end
end
