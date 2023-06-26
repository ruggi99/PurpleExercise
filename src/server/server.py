from flask import Flask, render_template, request as flask_request, jsonify, Response
from pathlib import Path
from time import time as time_time
from dataclasses import dataclass, asdict as dt_asdict
from threading import Thread, Event, Timer
from subprocess import check_output as sp_check_output, CalledProcessError as sp_CalledProcessError
from json import loads as json_loads, decoder as json_decoder
from random import randint as random_randint
from colorama import Fore, Style, init as colorama_init
from sys import platform as sys_platform


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
        # Init colorama
        if sys_platform == "win32":
            colorama_init()

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

        self.game_state = GameState(initial_points = self.CONFIG["lab"]["max_points"],
                                    max_seconds_available = self.CONFIG["lab"]["max_seconds_available"]
                          )
        
        return
    
    
    ##############################################
    #                   CREATE                   #
    ##############################################
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
        self.spawner_thread = GameThread(Thread(target = self._execute_spawner, daemon = True))
        self.checker_thread = GameThread(Thread(target = self._execute_checker, daemon = True))
        return

    
    ##############################################
    #                START / STOP                #
    ##############################################
    def _start_game(self) -> None:
        print(f"{Fore.GREEN}{Style.BRIGHT}[+]{Style.RESET_ALL} Starting game")
        self.game_state.start()
        self._start_threads()
        self._start_timer()
    

    def _end_game(self) -> None:
        print(f"{Fore.GREEN}{Style.BRIGHT}[+]{Style.RESET_ALL} Stopping game")
        self.game_state.stop()
        self._stop_threads()
        self._stop_timer()
    

    def _start_threads(self) -> None:
        self.spawner_thread.event.clear()
        self.spawner_thread.thread.start()
        print(f"{Fore.GREEN}{Style.BRIGHT}[+]{Style.RESET_ALL} Spawner thread started")

        self.checker_thread.event.clear()
        self.checker_thread.thread.start()
        print(f"{Fore.GREEN}{Style.BRIGHT}[+]{Style.RESET_ALL} Checker thread started")
        return


    def _stop_threads(self) -> None:
        self.spawner_thread.event.set()
        self.spawner_thread.thread.join()
        print(f"{Fore.GREEN}{Style.BRIGHT}[+]{Style.RESET_ALL} Spawner thread stopped")

        self.checker_thread.event.set()
        self.checker_thread.thread.join()
        print(f"{Fore.GREEN}{Style.BRIGHT}[+]{Style.RESET_ALL} Spawner thread stopped")
        return
    

    def _start_timer(self) -> None:
        self.timer = Timer(self.CONFIG["lab"]["max_seconds_available"], self._end_game)
        self.timer.start()
        return
    

    def _stop_timer(self) -> None:
        self.timer.cancel()
        return
        

    ##############################################
    #               THREAD FUNCTIONS             #
    ##############################################
    def _execute_spawner(self) -> None:
        while True:
            random_number = random_randint(1, 5)
            command = f"powershell -ep bypass {VULN_SPAWNER_PATH} -limit {random_number}"
            # check_output raises CalledProcessError if exit-code is non-zero
            try:
                _ = sp_check_output(command, cwd = VULN_SPAWNER_CWD, text = True)

            except sp_CalledProcessError:
                print(f"{Fore.RED}{Style.BRIGHT}[-]{Style.RESET_ALL} Error: spawner returned non-zero exit-code")

            if self.spawner_thread.event.wait(self.CONFIG["lab"]["spawner_time_interval"]):
                break

        return


    def _execute_checker(self) -> None:
        while True:
            command = f"powershell -ep bypass {VULN_CHECKER_PATH}"
            # check_output raises CalledProcessError if exit-code is non-zero
            try:
                _ = sp_check_output(command, cwd = VULN_CHECKER_CWD, text = True)
            
            except sp_CalledProcessError:
                print(f"{Fore.RED}{Style.BRIGHT}[-]{Style.RESET_ALL} Error: checker returned non-zero exit-code")
            
            response = self._load_json(GAME_STATE_PATH, encoding='utf-8-sig')
            
            if not response["status"]:
                print(f"{Fore.RED}{Style.BRIGHT}[-]{Style.RESET_ALL} Error: {response['error']}")
                continue
            
            if ("points" not in response["res"]) or ("game_ended" not in response["res"]):
                print(f"{Fore.RED}{Style.BRIGHT}[-]{Style.RESET_ALL} Error: missing key points or game_ended")
                continue
            
            self._update_game_state(response["res"])

            if self.checker_thread.event.wait(self.CONFIG["lab"]["checker_time_interval"]):
                break
        return
    

    def _update_game_state(self, state : dict) -> None:
        # Update current points
        self.game_state.points -= state["points"]
        
        # Update end game
        if self.game_state.points < 0 or state["game_ended"]:
            self._end_game()

        return


    ##############################################
    #                   CONFIG                   #
    ##############################################
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
            self._start_game()

            return "Ok"

        return "Error"


    def index(self) -> str:
        return render_template("index.html")
    

    def data(self) -> Response:
        response = jsonify(dt_asdict(self.game_state))
        response.headers.add("Access-Control-Allow-Origin", "*")
        return response


    def red_team(self) -> str:
        if "password" not in flask_request.args:
            return "Error"

        if flask_request.args["password"] != self.RED_PASSWORD:
            return "Error"

        red_target = self.CONFIG["lab"]["red_target"]
        red_user = self.CONFIG["lab"]["user_credentials"]["user"]
        red_password = self.CONFIG["lab"]["user_credentials"]["password"]
        return render_template("red_team.html", red_target=red_target, red_user=red_user, red_password=red_password)


##############################################       
#                  DATACLASSES               #
##############################################
@dataclass
class GameState:
    initial_points : int
    max_seconds_available: int
    points : int = 0
    start_time : float = 0
    game_ended : bool = False

    def start(self) -> None:
        self.points = self.initial_points
        self.start_time = time_time()
        self.game_ended = False
    
    def stop(self) -> None:
        self.game_ended = True


@dataclass
class GameThread:
    thread : Thread
    event: Event = Event()


##############################################       
#                   START                    #
##############################################
if __name__ == "__main__":
    server = Server()
    server.run()
