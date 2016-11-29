import os
import subprocess
import sys

def main():
    """Bash shim"""
    # This feels so dirty it feels so right.
    pyocalypse_path = os.path.dirname(__file__)
    abspath = os.path.join(pyocalypse_path, 'gogo.sh')
    if True:
        # Send all arguments (but not script name) to Bash script.
        #subprocess.call([abspath,] + sys.argv[1:])
        proj_dir = subprocess.check_output([abspath,] + sys.argv[1:])
        proj_dir = proj_dir.strip()
        print(proj_dir.decode())
    else:
        # NOTE/2016-11-29: The subprocess.check_output happens in a
        # subshell, so the `source .bashrc-client` doesn't stick.
        # I tried using os.execv() but was having issues... so for
        # now just sticking with gogo bash function. You can access
        # Python route via `pyocalypse-gogo`.
        print("abspath: %s" % (abspath,))
        print("sys.argv: %s" % (sys.argv[1:],))
        sys.stdout.flush()
        os.execv(abspath, sys.argv[1:])

