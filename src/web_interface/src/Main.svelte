<script lang="ts">
  import type { DataType } from "./types";
  const fetchDataIntervalSeconds = 10000;
  const updateTimeIntervalSeconds = 800;
  const URL = import.meta.env.DEV ? "http://localhost:5000" : "";

  let initialData = {};
  let data: DataType | null = null;
  let percentage = 0;
  let remaining_time = "";
  let color = "";

  async function initData() {
    const response = await fetch(URL + "/data.json");
    initialData = await response.json();
  }

  async function fetchData() {
    const response = await fetch(URL + "/data.json");
    data = (await response.json()) as DataType;

    percentage = (data.points * 100) / data.initial_points;

    if (percentage > 60) {
      color = "green";
    } else if (percentage > 20) {
      color = "yellow";
    } else {
      color = "red";
    }
  }

  function updateTime() {
    const now = new Date().getTime();
    const seconds_elapsed =
      data.start_time == 0 ? 0 : now / 1000 - data.start_time;
    const timezone = new Date(0).getTimezoneOffset();
    const time_remained = Math.max(
      data.max_seconds_available - seconds_elapsed,
      0
    );
    remaining_time = new Date(time_remained * 1000 + timezone * 60 * 1000)
      .toLocaleTimeString()
      .substring(0, 8);
  }

  initData().then(async () => {
    await fetchData();
    updateTime();

    setInterval(fetchData, fetchDataIntervalSeconds);
    setInterval(updateTime, updateTimeIntervalSeconds);
  });
</script>

<div class="box" data-color={color}>
  {#if data != null}
    {#if data.game_ended}
      <h2 style="text-align:center;">La partita è finita</h2>
    {:else if data.start_time == 0}
      <h2 style="text-align:center;">La partita deve ancora cominciare</h2>
    {:else}
      <p class="score">Score: {data.points}/{data.initial_points}</p>
      <p class="progress">Progress: {percentage}%</p>
      <p class="time">Time remained: {remaining_time}</p>
      <div class="progress-container" style="margin-bottom:10px">
        <div id="progress" class="progress-full">
          <div class="progress-value" style:width={percentage + "%"} />
        </div>
      </div>
      <slot />
    {/if}
  {/if}
</div>
