import sys
import os 
import re
import copy
import time
from datetime import datetime
import zipfile
import krpc
import pyqtgraph as pg

from icecream import ic
import tempfile
import shutil
import logging
import json
import pickle

from typing import Tuple, Optional

from PyQt6.QtWidgets import *

from PyQt6.QtGui import QAction, QIcon, QFont
from PyQt6.QtCore import Qt,QTimer, pyqtSignal, QEvent,pyqtSlot

import numpy as np
import polars as pl

from flight_threads import kRPCReader


TELEMETRY = [
    "mean_altitude",
    "latitude",
    "longitude",
    "speed",
    "pitch",
    "heading",
    "roll",
    "dynamic_pressure",
    "aerodynamic_force",
    "thrust_specific_fuel_consumption"
]
CONTROL = [
    "throttle",
    "pitch",
    "yaw",
    "roll",
    "",
]


class MainWindowMenu(QMenuBar):
    def __init__(self):
        super().__init__()
        file = self.addMenu("&File")

        
        self.open_settings = QAction("Settings", self)
        file.addAction(self.open_settings)
        self.edit = self.addMenu("&Edit")
        self.help = self.addMenu("&Help")
        return

class ConnectionWidget(QWidget):
    def __init__(self):
        super().__init__()

        self.set_UI()

    def set_UI(self):
        self.connect_layout = QHBoxLayout()
        
        self.rKPC_connect_button = QPushButton("Connect to rKPC")
        self.rKPC_connect_button.clicked.connect(self.connect_rKPC)
        self.rKPC_status = QLabel()
        self.rKPC_status.setFixedSize(20,20)
        self.rKPC_status.setStyleSheet("background-color: red; border: 1px solid black;")
        self.rKPC_reader = kRPCReader()

        self.fc_connect_button = QPushButton("Connect to Flight Controller")
        self.fc_connect_button.clicked.connect(self.connect_fc)
        self.fc_status = QLabel()
        self.fc_status.setFixedSize(20,20)
        self.fc_status.setStyleSheet("background-color: red; border: 1px solid black;")


        self.connect_layout.addWidget(self.rKPC_connect_button)
        self.connect_layout.addWidget(self.rKPC_status)
        self.connect_layout.addWidget(self.fc_connect_button)
        self.connect_layout.addWidget(self.fc_status)

        self.setLayout(self.connect_layout)

    def connect_rKPC(self):
        self.rKPC_reader.start()
        time.sleep(0.5)
        if self.rKPC_reader.connected:
            self.rKPC_status.setStyleSheet("background-color: green; border: 1px solid black;")
        else:
            self.rKPC_status.setStyleSheet("background-color: red; border: 1px solid black;")

        
    
    def connect_fc(self):

        return

class TelemetryViewer(QWidget):
    def __init__(self, telemetry: str,window_seconds: float =60.0):
        super().__init__()
        pg.setConfigOptions(antialias = False)
        self.telemtry = telemetry
        self.window_seconds = window_seconds

        self.timestamps = []      # list of float timestamps (seconds)
        self.values = []

        self.init_UI()
        return
    
    def init_UI(self):
        self._layout = QVBoxLayout()
        self.plot = pg.PlotWidget()
        self.plot.setTitle(f"{self.telemtry} (Last {self.window_seconds} seconds)")
        self.plot.showGrid(x=True, y=True)
        self.curve = self.plot.plot([], [], pen='y')
        self._layout.addWidget(self.plot)

        self.setLayout(self._layout)

        self.timer = QTimer()
        self.timer.timeout.connect(self.update_plot)
        self.timer.start(10)

        return
    
    def update_values(self,val:float):
        self.now = time.time()
        self.values.append(val)
        self.timestamps.append(self.now)
        return
    
    def update_plot(self):
        # If no data, don't do anything
        if len(self.timestamps) == 0:
            return
        
        cutoff = self.now - self.window_seconds
        while len(self.timestamps) > 0 and self.timestamps[0] < cutoff:
                self.timestamps.pop(0)
                self.values.pop(0)
        
        self.curve.setData(self.timestamps, self.values)

        self.plot.setXRange(cutoff, self.now)

        if len(self.values) > 0:
                ymin = min(self.values)
                ymax = max(self.values)
                if ymin == ymax:
                    ymin -= 1
                    ymax += 1
                self.plot.setYRange(ymin, ymax)
        return


class TelemetryWindow(QMdiSubWindow):
    #to be connected to the kRPC
    def __init__(self,telemetry):
        super().__init__()
        self.setObjectName(telemetry)
        self.telemetry = telemetry
        
        self.setWindowTitle(self.telemetry)
        self.setWindowFlags(Qt.WindowType.Window
                            | Qt.WindowType.WindowTitleHint
                            | Qt.WindowType.WindowMinMaxButtonsHint)
        self.set_UI()
        self.show()

    def set_UI(self):
        self.viewer = TelemetryViewer(self.telemetry)

        self.setWidget(self.viewer)


class MonitoringWidget(QWidget):
    def __init__(self):
        super().__init__()
        self.setUI()
        return
    def setUI(self):
        self._layout = QVBoxLayout()
        self.mdi = QMdiArea()
        self._layout.addWidget(self.mdi)
        for teleme in TELEMETRY:
            telemetry_window = TelemetryWindow(teleme)
            self.mdi.addSubWindow(telemetry_window)

        QTimer.singleShot(0,self.arrange_subwindows)
        self.setLayout(self._layout)
        return
    
    def arrange_subwindows(self):
        cols = 5
        rows = 2

        subwindows = self.mdi.subWindowList()
        mdi_size = self.mdi.viewport().size()
        
        w = mdi_size.width() // cols
        h = mdi_size.height() // rows
        #ic("sig",w,h)
        for i, window in enumerate(subwindows):
            row = i // cols
            col = i % cols
            window.setGeometry (col*w,row*h,w,h)
        #self.mdi.tileSubWindows()

    @pyqtSlot(dict)
    def telemetry_updated(self,telemetry_dict:dict):
        #ic(telemetry_dict)
        subwindows = self.mdi.subWindowList()
        for window in subwindows:
            widget = window.widget()
            title = window.windowTitle()
            widget.update_values(telemetry_dict[title]) 
        
        return


class FMMainWindow(QWidget):
    def __init__(self,tmp_folder):
        super().__init__()
        self.tmp_folder = tmp_folder
        self.setWindowTitle('KSP Flight Monitor')

        self.set_UI()


    def set_UI(self):
        self._layout = QVBoxLayout()
        menu = MainWindowMenu()
        menu.setObjectName("MainWindowMenu")
        self._layout.setMenuBar(menu)
        
        #connection layout
        self.connect_widget = ConnectionWidget()

        self._layout.addWidget(self.connect_widget,1)

        self.monitoring_widget = MonitoringWidget()
        self._layout.addWidget(self.monitoring_widget,9)

        self.connect_widget.rKPC_reader.telemetry_updated.connect(self.monitoring_widget.telemetry_updated)


        self.setLayout(self._layout)
        return
    
    def changeEvent(self, event: QEvent) -> None:
        if event.type() == QEvent.Type.WindowStateChange:
            state = self.windowState()

            # Fullscreen (F11 / showFullScreen())
            if state & Qt.WindowState.WindowFullScreen:
                self.on_fullscreen_enter()
            else:
                self.on_fullscreen_exit()
        super().changeEvent(event)

    def on_fullscreen_enter(self):
        self.monitoring_widget.arrange_subwindows()
        # put your code here

    def on_fullscreen_exit(self):
        self.monitoring_widget.arrange_subwindows()
        
        # put your code here
    
