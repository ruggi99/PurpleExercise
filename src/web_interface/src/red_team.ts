import './app.css'
import RedTeam from './RedTeam.svelte'

const app = new RedTeam({
  target: document.getElementById('app'),
})

export default app
