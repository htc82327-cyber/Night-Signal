from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
required=[
"Makefile","control","Tweak.xm","NightSignalTweak.plist",
"NightSignal/Makefile","NightSignal/Info.plist","NightSignal/RootViewController.m",
"PovoZka/Makefile","PovoZka/Info.plist","PovoZka/ChatViewController.m",
"NightSignal/Resources/scream.wav",".github/workflows/build.yml"
]
missing=[x for x in required if not (root/x).exists()]
if missing:
 print("Missing:",*missing,sep="\n- ");sys.exit(1)
print("Night Signal + PovoZka source tree OK")
