import os 
os.environ.setdefault("OPENBLAS_NUM_THREADS", "8")  
os.environ.setdefault("OMP_NUM_THREADS", "8")
os.environ.setdefault("NUMEXPR_NUM_THREADS", "8")


import sys

import icecream as ic
import tempfile
import shutil
import logging

from typing import Tuple, Optional

from PyQt6.QtWidgets import (
    QApplication,
    QWidget,
    QMainWindow,
    QToolBar,
    QStackedLayout
)

from PyQt6.QtGui import QAction
from PyQt6.QtCore import Qt

from flight_window import FMMainWindow

import numpy as np
#print(f"Numpy Config : {np.__config__.show()}")

TMP_FOLDER = os.path.join(tempfile.gettempdir(),"CytoMEMS_Analyzer",str(np.random.randint(0,100000)))




def main():
    
    cma_app = QApplication(sys.argv)
    main_window = FMMainWindow(TMP_FOLDER)
    main_window.setObjectName("FMMainWindow")
    main_window.resize(800,600)
    main_window.show()

    #with open(resource_path("resource/style.qss"), "r") as f:
        #_style = f.read()
        #cma_app.setStyleSheet(_style)
    
    sys.exit(cma_app.exec())


    return







if __name__ == "__main__":
    os.makedirs(TMP_FOLDER, exist_ok=True)
    logfile = os.path.join(TMP_FOLDER,"cma_debug.log")
    logging.basicConfig(filename=logfile, level=logging.DEBUG, filemode="w")

    try:
        exit_code = main()
    
    finally:
        try:
            logging.shutdown()
            shutil.rmtree(TMP_FOLDER)
            print(f"Erased : {TMP_FOLDER}")
        except:
            print(f"Couldn't erase the temp folder : {TMP_FOLDER}")

    sys.exit(exit_code)
