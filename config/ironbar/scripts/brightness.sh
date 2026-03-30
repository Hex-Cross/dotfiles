#!/bin/bash
# Gets brightness percentage (requires brightnessctl)
brightnessctl -m | cut -d, -f4
