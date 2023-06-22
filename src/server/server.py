from flask import Flask, render_template, request as flask_request
from pathlib import Path
from time import time as time_time, sleep as time_sleep
from dataclasses import dataclass, asdict as dt_asdict
from threading import Thread
from subprocess import check_output as sp_check_output
from json import loads as json_loads, decoder as json_decoder


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
        # Create flask app
        self.app = Flask(__name__)
        
        # Load config
        self.config = self._load_json(CONFIG_JSON_PATH)
        
        if self.config is None:
            raise ValueError("config is None")
        
        # Init game state
        self.game_state = GameState(points = self.config["points"],
                                    initial_points = self.config["points"],
                                    max_seconds_available = self.config["max_seconds_available"]
                          )
        return
    
    
    def run(self) -> None:
        self._add_endpoints()
        self._create_threads()

        self.app.run(host = SERVER_IP, port = SERVER_PORT, debug = True)
        return


    def _add_endpoints(self) -> None:
        self.app.add_url_rule("/start", view_func = self.start, methods = ["POST"])
        self.app.add_url_rule("/", view_func = self.index, methods = ["GET"])
        self.app.add_url_rule("/data.json", view_func = self.data, methods = ["GET"])
        self.app.add_url_rule("/red_team", view_func  =self.red_team, methods = ["GET"])
        return


    def _create_threads(self) -> None:
        self.spawner_thread = GameThread()
        self.checker_thread = GameThread()

        self.spawner_thread.thread = Thread(target = self._execute_spawner, daemon = True)
        self.checker_thread.thread = Thread(target = self._execute_checker, daemon = True)
        return


    def _start_threads(self) -> None:
        self.spawner_thread.up = True
        self.spawner_thread.thread.start()

        self.checker_thread.up = True
        self.checker_thread.thread.start()
        return


    def _stop_threads(self) -> None:
        self.spawner_thread.up = False
        self.spawner_thread.thread.join()

        self.checker_thread.up = False
        self.checker_thread.thread.join()
        return
        

    def _update_game_state(self, state : dict) -> None:
        # Update current points
        self.game_state.points -= state["points"]
        
        # Update end game
        if self.game_state.points < 0:
            self.game_state.game_ended = True

        else:
            self.game_state.game_ended = state["game_ended"]
        
        # Terminate threads if game ended
        if self.game_state.game_ended:
            self._stop_threads()

        return

    
    def _execute_spawner(self) -> None:
        while self.spawner_thread.up:
            command = f"powershell -ep bypass {VULN_SPAWNER_PATH}"
            _ = sp_check_output(command, cwd = "../../", text = True) # We should check this

            time_sleep(self.config["spawnerTimeInterval"])

        return


    def _execute_checker(self) -> None:
        while self.checker_thread.up:
            command = f"powershell -ep bypass {VULN_CHECKER_PATH}"
            response = sp_check_output(command, cwd = "../../", text = True) # We should check this
            
            try:
                response_json = json_loads(response)
                self._update_game_state(response_json)

            except json_decoder.JSONDecodeError as e:
                pass # need to handle this case

            time_sleep(self.config["checkerTimeInterval"])
        return


    def _load_json(self, json_path : str) -> dict | None:
        # Check json existance
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
    def start(self) -> str:
        if self.game_state.start_time != 0:
            return "Error"

        if "password" not in flask_request.form:
            return "Error"

        if flask_request.form["password"] == START_PASSWORD:
            # Set start time
            self.game_state.start_time = time_time()
            
            # Threads
            self._start_threads() 

            return "Ok"

        return "Error"


    def index(self) -> str:
        return render_template("index.html", data = self.config)
    

    def data(self) -> dict:
        return dt_asdict(self.game_state)


    def red_team(self) -> str:
        if "password" not in flask_request.form:
            return "Error"

        if flask_request.form["password"] != RED_PASSWORD:
            return "Error"

        win_condition = self.config["win_condition"]
        return render_template("red_team.html", win_condition)




##############################################       
#                  DATACLASSES               #
##############################################
@dataclass
class GameState:
    points : int
    initial_points : int
    max_seconds_available: int
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
