<script lang="ts">
  import Main from "./Main.svelte";
</script>

<Main>
  <!-- svelte-ignore missing-declaration -->
  <p class="win_condition">
    Utente da mettere negli Enterprise Admin: {red_target}
  </p>
  <p class="win_condition">
    Utente accesso iniziale: {red_user}
  </p>
  <p class="win_condition">
    Password accesso iniziale: {red_password}
  </p>
</Main>
