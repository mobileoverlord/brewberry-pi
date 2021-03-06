defmodule Ctrl.ControllerServer do
  @moduledoc """
  The Controller process.
  This is where is all comes together.
  """
  use GenServer

  alias Ctrl.Sample
  alias Ctrl.BrewHouse
  alias Ctrl.Controller
  alias Ctrl.ControllerServer
  alias Ctrl.Heater
  alias Ctrl.Thermometer

  @heater_mod Application.get_env(:ctrl, :heater)
  @thermometer_mod Application.get_env(:ctrl, :thermometer)

  ## Client interface

  @spec start_link() :: {:ok, pid}
  def start_link(),
    do: GenServer.start_link(__MODULE__, [], [name: __MODULE__])

  @spec resume(GenServer.server) :: :ok
  def resume(controller \\ __MODULE__),
    do: GenServer.cast(controller, :resume)

  @spec pause(GenServer.server) :: :ok
  def pause(controller \\ __MODULE__),
    do: GenServer.cast(controller, :pause)

  @spec mash_temperature(GenServer.server, float | integer) :: :ok
  def mash_temperature(controller \\ __MODULE__, new_temp),
    do: GenServer.cast(controller, {:mash_temp, new_temp})


  ## Server callbacks

  defstruct [:controller, :thermometer, :heater]

  @typep t :: %ControllerServer{
    controller: Controller.t,
    thermometer: Thermometer.t,
    heater: Heater.t
  }

  @spec init(term) :: {:ok, t}
  def init(_opts) do
    {:ok, %ControllerServer{
            controller: Controller.new(BrewHouse.new),
            thermometer: Thermometer.new(@thermometer_mod),
            heater: Heater.new(@heater_mod)}}
  end

  @spec handle_cast(atom | {atom, any}, t) :: {:noreply, t}

  def handle_cast(:resume, config) do
    {:noreply, %{config | controller: Controller.resume(config.controller)}}
  end

  def handle_cast(:pause, config) do
    {:noreply, %{config | controller: Controller.pause(config.controller)}}
  end

  def handle_cast({:tick, now}, config) do
    new_temp = Thermometer.read(config.thermometer)
    controller = Controller.update(config.controller, now, new_temp)
    mode = Controller.mode?(controller)
    mash_temp = Controller.mash_temperature?(controller)
    on_off = Heater.update(config.heater, mode)

    sample = Sample.new(time: now,
      temperature: new_temp,
      heater: on_off,
      mode: mode,
      mash_temperature: mash_temp)

    Ctrl.TimeSeries.update(now |> DateTime.to_unix, sample)

    {:noreply, %{config | controller: controller}}
  end

 def handle_cast({:mash_temp, new_temp}, config) do
    {:noreply, %{config | controller: Controller.mash_temperature(config.controller, new_temp)}}
  end

end
