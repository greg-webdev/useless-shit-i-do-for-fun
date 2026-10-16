import os
import time
import random
import sys
import shutil

# Color Palette
G    = '\033[32m'    # Green
BG   = '\033[92m'   # Bright Green
DG   = '\033[2;32m'  # Dim Green
R    = '\033[31m'    # Red
BR   = '\033[91m'   # Bright Red
CY   = '\033[36m'    # Cyan
YW   = '\033[33m'    # Yellow
W    = '\033[37m'    # White
INV  = '\033[7m'     # Invert Colors
RES  = '\033[0m'     # Reset

def glitch_line(length):
    chars = "010101#@$%&*_+=§?ø█▓▒░"
    return "".join(random.choice(chars) for _ in range(length))

def slow_type(text, speed=0.01):
    for char in text:
        sys.stdout.write(char)
        sys.stdout.flush()
        time.sleep(speed)
    print()

def visual_hack():
    cols, rows = shutil.get_terminal_size()
    
    # 1. NEURAL HANDSHAKE (Flicker Effect)
    for _ in range(10):
        sys.stdout.write(f"\r{INV}{' ' * cols}{RES}")
        sys.stdout.flush()
        time.sleep(0.05)
        sys.stdout.write(f"\r{' ' * cols}")
        sys.stdout.flush()
        time.sleep(0.05)
    
    slow_type(f"{BG}[!] BIOMETRIC SCAN: AUTHORIZED", 0.05)
    slow_type(f"{BG}[!] NEURAL UPLINK: ESTABLISHED", 0.05)
    time.sleep(1)

    # 2. THE GLOBAL PING (Map Simulation)
    print(f"\n{CY}--- GLOBAL NODE PING ---{RES}")
    locations = ["LONDON", "TOKYO", "MOSCOW", "NEW YORK", "BERLIN", "SINGAPORE"]
    for loc in locations:
        print(f"{W}[+]{RES} Pinging {loc.ljust(12)} ", end="")
        for _ in range(3):
            sys.stdout.write(f"{G}.{RES}")
            sys.stdout.flush()
            time.sleep(0.3)
        print(f" {BG}[STABLE]{RES}")

    # 3. DIRECTORY DECONSTRUCTION (Visual Tree)
    print(f"\n{YW}DECONSTRUCTING FILE SYSTEM...{RES}")
    for i in range(40):
        indent = " " * (i % 15)
        print(f"{DG}{indent}└── {glitch_line(random.randint(10, 30))}{RES}")
        time.sleep(0.04)

    # 4. DATA OVERFLOW (The "Waterfall")
    print(f"\n{BR}CRITICAL OVERFLOW INITIATED{RES}")
    time.sleep(1)
    start_time = time.time()
    while time.time() - start_time < 15:
        line = glitch_line(cols - 1)
        # Randomly color parts of the line
        if random.random() > 0.8:
            print(f"{R}{line}{RES}")
        elif random.random() > 0.6:
            print(f"{YW}{line}{RES}")
        else:
            print(f"{G}{line}{RES}")
        time.sleep(0.03)

    # 5. THE CENTER BOX (Final Override)
    os.system('cls' if os.name == 'nt' else 'clear')
    mid_row = rows // 2
    for r in range(rows):
        if r == mid_row:
            print(f"{INV}{' SYSTEM BREACH SUCCESSFUL '.center(cols)}{RES}")
        else:
            print(f"{DG}{glitch_line(cols)}{RES}")
    time.sleep(3)

def cmd_radar():
    cols, rows = shutil.get_terminal_size()
    print(f"{G}Scanning for nearby ghosts...{RES}")
    for i in range(360, 0, -10):
        sys.stdout.write(f"\r{CY}RADAR SWEEP: {i}° [{('█'*(i//20)).ljust(18)}] TARGETS: {random.randint(0,5)}{RES}")
        sys.stdout.flush()
        time.sleep(0.1)
    print()

def main():
    os.system('cls' if os.name == 'nt' else 'clear')
    print(f"{BG}--- GENESIS VISUAL TERMINAL v10.0 ---{RES}")
    
    while True:
        try:
            cmd = input(f"\n{G}root@genesis:~# {RES}").lower().strip()
            if cmd == "hack":
                visual_hack()
            elif cmd == "radar":
                cmd_radar()
            elif cmd == "clear":
                os.system('cls' if os.name == 'nt' else 'clear')
            elif cmd == "exit":
                break
            elif cmd == "help":
                print(f"{G}hack{RES}  - High-intensity visual sequence")
                print(f"{G}radar{RES} - Interactive sweep animation")
                print(f"{G}clear{RES} - Wipe display")
            else:
                print(f"{R}Unknown Module.{RES}")
        except KeyboardInterrupt:
            print(f"\n{R}Safe Shutdown.{RES}")
            break

if __name__ == "__main__":
    main()