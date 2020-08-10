"""
    0. imports
    1. vars
    2. functions
    3. backup: copy published artifacts to backup folder
    4. clean: delete publish folder
    5. publish: copy artifacts to publish folder
    6. cleanup:
        6.1 get all items in backup folder
        6.2 delete items older than desired
"""

# 0. imports
import shutil
from datetime import datetime
import os
import sys

# 1. vars
artifactsPath = 'c:\\temp\\webDeploy'
publishPath = 'c:\\temp\\publishFolder'
bacupPath = 'c:\\temp\\backupFolder'
logPath = 'c:\\templog.txt
daysToKeep = 1

# 2. functions
def logThis(message):
    with open(logPath, 'a') as log_file:
        log_file.write("{0}: {1}\n".format(datetime.now(), message))

def backup():
    try:
        logThis("starting backup...")
        shutil.copytree(publishPath, os.path.join(backupPath, datetime.now().strftime("%Y%m%d-%H%M%S")))
        logThis("    completed backup")        
    except:
        logThis("backup failed")

def clean():
    try:
        logThis("deleting publish folder")
        shutil.rmtree(publishPath, ignore_errors=True)
        logThis("    deleted publish folder")
    except:
        logThis("failed clean")

def publish():
    try:
        logThis("starting publish...")
        shutil.copytree(artifactsPath, publishPath)
        logThis("    completed publish")
    except:
        logThis("failed publish...{0}".format(sys.exc_info()[0]))

def cleanup():
    try:
        logThis("starting cleanup...")
        with os.scandir(backupPath) as folders:
            for folder in folders:
                folderAge = datetime.now() - datetime.utcfromtimestamp(folder.stat().st_ctime)
                logMsg = '''
                    checking folder: {0}
                    folder time is: {1}
                    current time is: {2}
                    folder age is: {3}
                    '''.format(folder.name, datetime.utcfromtimestamp(folder.stat().st_ctime), datetime.now(), folderAge)
                logThis(logMsg)
                if folderAge.days > daysToKeep:
                    logThis("cleaning folder: {0}".format(folder.name))
                    shutil.rmtree(folder.path)
        logThis("    completed cleanup")
    except TypeError as typeError:
        logThis("failed cleanup...{0}".format(typeError.args))
    except AttributeError as attributeError:
        logThis("failed cleanup...{0}".format(attributeError.args))
    except:
        logThis("failed cleanup...{0}".format(sys.exc_info()[0]))

# 3. backup
backup()

# 4. clean
clean()

# 5. publish
publish()

# 6. cleanup
cleanup()
