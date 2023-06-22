from pathlib import Path
from json import loads as json_loads, decoder as json_decoder
from requests import post as requests_post
from getpass import getpass as gp_getpass


CONFIG_JSON_PATH  = "../config.json"


def load_json(json_path : str) -> dict:
    res = {"status" : False, "error" : "", "res" : ""}

    # Check json existance
    if not Path(json_path).is_file():
        res["error"] = "config file does not exist"
        return res

    # Read json
    with open(json_path, "r") as fd:
        json_file = fd.read()
    
    # Parse json
    try:
        res["res"] = json_loads(json_file)
        res["status"] = True
        return res

    except json_decoder.JSONDecodeError as e:
        res["error"] = "invalid config file format"
        return res


def main() -> None:
    res = load_json(CONFIG_JSON_PATH)
    if not res["status"]:
        raise ValueError(res["error"])
    
    config = res["res"]["server"]
    
    if not config["ip"] or not config["port"]:
        raise KeyError("Missing ip or port")

    url = f"http://{config['ip']}:{config['port']}"
    password = gp_getpass(prompt = "Password: ")
    data = {"password" : password}

    requests_post(url = url, data = data)

    return


if __name__ == "__main__":
    main()