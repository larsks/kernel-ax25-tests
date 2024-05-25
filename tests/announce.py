#!/usr/bin/python3

import argparse
import time

def parse_args():
    p = argparse.ArgumentParser()

    p.add_argument("--port", "-d")
    p.add_argument("--callsign", "-u")
    p.add_argument("--ssid", "-s")

    return p.parse_args()


def main():
    args = parse_args()
    print(f"Incoming connection on {args.port} from {args.callsign} ({args.ssid})", flush=True)


if __name__ == "__main__":
    main()
