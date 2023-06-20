from flask import Flask, render_template
from json import loads as json_loads, decoder as json_decoder
from time import time as time_time, sleep as time_sleep
from os import listdir as os_listdir
from subprocess import call as subprocess_call
from threading import Thread


##############################################
#               GLOBAL VARIABLES             #
##############################################
APP = Flask(__name__)
JSON_PATH = "../lab.json"
SCRIPT_PATH = "../../spawner.ps1"
THREAD_SLEEP_SECONDS = 20 
START_TIME = 0


##############################################
#                  ENDPOINTS                 #
##############################################
@APP.route("/", methods = ["GET"])
def index():
    return render_template("index.html")


@APP.route("/static_data.json", methods = ["GET"])
def static_data() -> dict:
    lab_json = load_lab_json()

    max_score = get_score(lab_json)["max"]
    win_condition = get_win_condition(lab_json)
    max_seconds_available = get_max_seconds_available(lab_json)
    
    # Data could contain None
    data = {"max_score" : max_score,
            "win_condition" : win_condition,
            "max_seconds_available" : max_seconds_available,
            "start_time" : START_TIME}
    
    return data
    

@APP.route("/score.json", methods = ["GET"])
def score() -> dict:
    lab_json = load_lab_json()
    
    # Score data could contain None
    score_data = get_score(lab_json)

    return score_data # keys: current - max - percentage


##############################################
#         ENDPOINTS SUPPORT FUNCTIONS        #
##############################################
def load_lab_json() -> dict | None:
    with open(JSON_PATH, "r") as fd:
        lab_json = fd.read()
    
    try:
        return json_loads(lab_json)

    except json_decoder.JSONDecodeError:
        return None


def get_score(lab_json : dict) -> dict | None:
    score = {"current" : 0, "max" : 0, "percentage" : 0}
    
    try:
        for lab_info in lab_json["vulns"].values():

            if lab_info["solved"]: 
                score["current"] += lab_info["score"]

            score["max"] += lab_info["score"]

    except KeyError:
        return None

    score["percentage"] = round(score["current"] / score["max"], 5)
    return score



def get_win_condition(lab_json : dict) -> float | None:
    try:
        return lab_json["win_condition"]

    except KeyError:
        return None


def get_max_seconds_available(lab_json : dict) -> float | None:
    try:
        return lab_json["max_seconds_available"]

    except KeyError:
        return None


##############################################
#               THREAD FUNCTIONS             #
##############################################
def execute_scripts() -> None:

    while True: # we should stop this with a variable

        command = f"powershell -ep bypass {SCRIPT_PATH}"
        subprocess_call(command, cwd="../../") # We should check this

        time_sleep(THREAD_SLEEP_SECONDS)

    return



if __name__ == "__main__":
    script_thread = Thread(target = execute_scripts, daemon = True)
    script_thread.start()

    START_TIME = time_time()
    
    APP.run("0.0.0.0", debug = True)
