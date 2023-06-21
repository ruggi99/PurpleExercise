from flask import Flask, render_template
from pathlib import Path
from time import time as time_time, sleep as time_sleep
from dataclasses import dataclass
from threading import Thread
from subprocess import check_output as sp_check_output


##############################################
#               GLOBAL VARIABLES             #
##############################################
CONFIG_JSON_PATH  = "../../AD_network.json"
VULN_SPAWNER_PATH = "../../spawner.ps1"
VULN_CHECKER_PATH = "../../checker.ps1"

SERVER_IP   = "0.0.0.0"
SERVER_PORT = 5000

START_PASSWORD = "abcd"
RED_PASSWORD   = "michiamovirgolasonoungattino" 


##############################################
#                   SERVER                   #
##############################################
class Server():
    def __init__(self) -> None:
        self.app = Flask(__name__)

        self.config = self._load_json(CONFIG_JSON_PATH)
        
        if self.config is None:
            raise ValueError("config is None")

        self.game_state = GameState(points = self.config["points"])

        self.spawner_thread = GameThread()
        self.checker_thread = GameThread()
        return
    
    
    def run() -> None:
        self.spawner_thread.thread = Thread(target = _execute_spawner, args = (self, ), daemon = True)
        self.checker_thread.thread = Thread(target = _execute_checker, args = (self, ), daemon = True)

        self.app.run(host = SERVER_IP, port = SERVER_PORT, debug = True)
        return


    def _update_game_state(state : dict) -> None:
        # Current points
        self.game_state.points -= state.points
        
        # End game
        if self.game_state.points < 0:
            self.game_state.game_ended = True

        else:
            self.game_state.game_ended = state.game_ended
        
        # Terminate threads if game ended
        if self.game_state.game_ended:
            self.spawner_up = False
            self.checker_up = False
        return

    
    def _execute_spawner() -> None:
        while self.spawner_thread.up:
            command = f"powershell -ep bypass {VULN_SPAWNER_PATH}"
            _ = sp_check_output(command, cwd = "../../", text = True) # We should check this

            time_sleep(self.config["spawnerTimeInterval"])

        return


    def _execute_checker() -> None:
        while self.checker_thread.up:
            command = f"powershell -ep bypass {CHECKER_PATH}"
            response = sp_check_output(command, cwd = "../../", text = True) # We should check t
            
            try:
                response_json = json_loads(response)
                self._update_game_state(response_json)

            except json_decoder.JSONDecodeError as e:
                pass # need to handle this case
        return


    def _load_json(json_path : str) -> dict | None:
        # Check json existance
        if not Path(json_path).exists():
            return None

        if not Path(json_path).is_file():
            return None

        # Read json
        with open(json_path, "r") as fd:
            json_file = fd.read()
        
        # Parse json
        try:
            return json_loads(json_file)

        except json_decoder.JSONDecodeError as e:
            return None


    ##############################################
    #                  ENDPOINTS                 #
    ##############################################
    @self.app.route("/start", methods = ["POST"])
    def start():
        if self.game_state.start_time != 0:
            return

        if "password" not in request.form:
            return

        if request.form["password"] == START_PASSWORD:
            # Set start time
            self.game_state.start_time = time_time()
            
            # Threads
            self.spawner_thread.up = True
            self.spawner_thread.thread.start()

            self.checker_thread.up = True
            self.checker_thread.thread.start()

        return


    @self.app.route("/", methods = ["GET"])
    def index():
        return render_template("index.html")
    

    @self.app.route("/data.json", methods = ["GET"])
    def data() -> dict:
        return dataclasses.asdict(game_state)


    @self.app.route("/red_team", methods = ["GET"])
    def red_team():
        if "password" not in request.form:
            return

        if request.form["password"] != RED_PASSWORD:
            return

        win_condition = self.config["win_condition"]
        return render_template("red_team.html", win_condition)




##############################################       
#                  DATACLASSES               #
##############################################
@dataclass
class GameState:
    points : int
    game_ended : bool = False
    start_time : float = 0


@dataclass
class GameThread:
    thread : Thread = None
    up : bool = False



##############################################       
#                   START                    #
##############################################
if __name__ == "__main__":
    server = Server()
    server.run()
