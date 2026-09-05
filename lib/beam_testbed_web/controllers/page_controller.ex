defmodule BeamTestbedWeb.PageController do
  use BeamTestbedWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
