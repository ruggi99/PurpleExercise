from flask import Flask, render_template, request as flask_request, jsonify
from pathlib import Path
from time import time as time_time, sleep as time_sleep
from dataclasses import dataclass, asdict as dt_asdict
from threading import Thread
from subprocess import check_output as sp_check_output
from json import loads as json_loads, decoder as json_decoder


##############################################
#               GLOBAL VARIABLES             #
##############################################
CONFIG_JSON_PATH  = "../config.json"
VULN_SPAWNER_PATH = "./scripts/spawner.ps1"
VULN_CHECKER_PATH = "./scripts/checker.ps1"
VULN_SPAWNER_CWD = "../"
VULN_CHECKER_CWD = "../"
GAME_STATE_PATH = "../game_state.json"


##############################################
#                   SERVER                   #
##############################################
class Server():
    def __init__(self) -> None:
        # Create flask app
        self.APP = Flask(__name__)
        
        # Load config
        res = self._load_json(CONFIG_JSON_PATH)
        
        if not res["status"]:
            raise ValueError(res["error"])
        
        self.CONFIG = res["res"]
        
        # Check server config
        res = self._check_config()

        if not res["status"]:
            raise ValueError(res["error"])
        
        
        # Init server info
        self.SERVER_IP = self.CONFIG["server"]["ip"]
        self.SERVER_PORT = self.CONFIG["server"]["port"]

        self.START_PASSWORD = self.CONFIG["server"]["start_password"]
        self.RED_PASSWORD   = self.CONFIG["server"]["red_password"]

        self.game_state = GameState(points = self.CONFIG["lab"]["max_points"],
                                    initial_points = self.CONFIG["lab"]["max_points"],
                                    max_seconds_available = self.CONFIG["lab"]["max_seconds_available"]
                          )
        return
    

    def run(self) -> None:
        self._add_endpoints()
        self._create_threads()

        self.APP.run(host = self.SERVER_IP, port = self.SERVER_PORT, debug = True)
        return


    def _add_endpoints(self) -> None:
        self.APP.add_url_rule("/start", view_func = self.start, methods = ["POST"])
        self.APP.add_url_rule("/", view_func = self.index, methods = ["GET"])
        self.APP.add_url_rule("/data.json", view_func = self.data, methods = ["GET"])
        self.APP.add_url_rule("/red_team", view_func = self.red_team, methods = ["GET"])
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
        print("Spawner thread started");

        self.checker_thread.up = True
        self.checker_thread.thread.start()
        print("Checker thread started");
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
            res = sp_check_output(command, cwd = VULN_SPAWNER_CWD, text = True) # We should check this
            print(res)

            time_sleep(self.CONFIG["lab"]["spawner_time_interval"])

        return


    def _execute_checker(self) -> None:
        while self.checker_thread.up:
            command = f"powershell -ep bypass {VULN_CHECKER_PATH}"
            res = sp_check_output(command, cwd = VULN_CHECKER_CWD, text = True) # We should check this
            print(res)
            
            response = self._load_json(GAME_STATE_PATH, encoding='utf-8-sig')
            
            if not response["status"]:
                print(f"error: {response['error']}")
                continue
            
            if ("points" not in response["res"]) or ("game_ended" not in response["res"]):
                print(f"error: missing key points or game_ended")
                continue
            
            self._update_game_state(response["res"])

            time_sleep(self.CONFIG["lab"]["checker_time_interval"])
        return


    def _load_json(self, json_path : str, encoding : str = "utf-8") -> dict:
        res = {"status" : False, "error" : "", "res" : ""}

        # Check json existance
        if not Path(json_path).is_file():
            res["error"] = "config file does not exist"
            return res

        # Read json
        with open(json_path, "r", encoding=encoding) as fd:
            json_file = fd.read()
        
        # Parse json
        try:
            res["res"] = json_loads(json_file)
            res["status"] = True
            return res

        except json_decoder.JSONDecodeError as e:
            res["error"] = "invalid config file format"
            return res


    def _check_config(self) -> dict:
        res = {"status" : False, "error" : ""}

        # Check server parameters
        if not "server" in self.CONFIG:
            res["error"] = "missing server parameter"
            return res
        
        server_parameters = ["ip", "port", "start_password", "red_password"]

        for parameter in server_parameters:
            if parameter not in self.CONFIG["server"]:
                res["error"] = f"missing {parameter} parameter in server field"
                return res
        
        # Check lab parameters
        if not "lab" in self.CONFIG:
            res["error"] = "missing lab parameter"
            return res
        
        lab_parameters = ["red_target", "max_points", "max_seconds_available",
                          "spawner_time_interval", "checker_time_interval"]
        

        for parameter in lab_parameters:
            if parameter not in self.CONFIG["lab"]:
                res["error"] = f"missing {parameter} parameter in lab field"
                return res
        
        # No errors
        res["status"] = True
        return res


    ##############################################
    #                  ENDPOINTS                 #
    ##############################################
    def start(self) -> str:
        if self.game_state.start_time != 0:
            return "Error"

        if "password" not in flask_request.form:
            return "Error"

        if flask_request.form["password"] == self.START_PASSWORD:
            # Set start time
            self.game_state.start_time = time_time()
            
            # Threads
            self._start_threads() 

            return "Ok"

        return "Error"


    def index(self) -> str:
        return render_template("index.html")
    

    def data(self) -> dict:
        response = jsonify(dt_asdict(self.game_state))
        response.headers.add("Access-Control-Allow-Origin", "*")
        return response


    def red_team(self) -> str:
        if "password" not in flask_request.form:
            return "Error"

        if flask_request.form["password"] != self.RED_PASSWORD:
            return "Error"

        red_target = self.CONFIG["lab"]["red_target"]
        return render_template("red_team.html", red_target)




##############################################       
#                  DATACLASSES               #
##############################################
@dataclass
class GameState:
    points : int
    initial_points : int
    max_seconds_available: int
    start_time : float = 0
    game_ended : bool = False


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
