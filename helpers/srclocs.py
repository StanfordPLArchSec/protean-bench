#!/usr/bin/python3

import sys
import json
import types

def get_srcloc(line: str) -> str:
    j = json.loads(line)
    assert len(j["Symbol"]) == 1
    symbol = types.SimpleNamespace(**j["Symbol"][0])
    addr = j["Address"].removeprefix("0x")
    if len(symbol.FileName) == 0 or \
       symbol.Line == 0 or \
       symbol.Column == 0: # TODO: Maybe too strict?
        return None
    return f"{addr} {symbol.FileName}:{symbol.Line}:{symbol.Column}"

for line in sys.stdin:
    srcloc = get_srcloc(line)
    if srcloc:
        print(srcloc)

