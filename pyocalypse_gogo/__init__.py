import os
import subprocess
import sys

def main():
    """Bash shim"""
    # This feels so dirty it feels so right.
    pyocalypse_path = os.path.dirname(__file__)
    abspath = os.path.join(pyocalypse_path, 'gogo.sh')
    # Send all arguments (but not script name) to Bash script.
    #subprocess.call([abspath,] + sys.argv[1:])
    proj_dir = subprocess.check_output([abspath,] + sys.argv[1:])
    proj_dir = proj_dir.strip()
    print(proj_dir.decode())

