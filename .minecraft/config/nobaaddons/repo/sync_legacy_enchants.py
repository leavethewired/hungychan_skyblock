#!/usr/bin/env python3

import os
import json

enchant_files = os.listdir("enchantments")
built: dict[str, list[dict]] = {
	"standard": [],
	"ultimate": [],
	"stacking": [],
}

for file in enchant_files:
	with open(f"enchantments/{file}") as f:
		data = json.load(f)
		built[data.pop("type")].append(data)

with open("item_modifiers/enchants.json", mode="w") as f:
	dump = json.dumps(built, indent=2).replace("  ", "\t")
	f.write(dump)
