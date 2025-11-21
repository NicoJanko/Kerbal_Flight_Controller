import socket
from icecream import ic

import krpc
import json

from PyQt6.QtCore import pyqtSignal
from PyQt6 import QtCore, QtGui
from queue import Queue




TELEMETRY = {
    "mean_altitude" : "vessel_flight",
    #"latitude" : "vessel",
    #"longitude" : "vessel",
    "pitch" : "vessel_flight",
    "heading" : "vessel_flight",
    "roll" : "vessel_flight",
    #"dynamic_pressure" : "vessel",
    "speed" : "flight",
    "moment_of_inertia":"vessel",
    "available_torque":"vessel",
    "angular_velocity":"pid"
}
CONTROL = [
    "throttle",
    "pitch",
    "yaw",
    "roll"
]

class kRPCReader(QtCore.QThread):
    telemetry_updated = pyqtSignal(dict, dict)
    def __init__(self):
        super().__init__()
        self.connected = False
        self.running = False
        self.stream_added = False
        self.vessel = None
        self.telemetry_stream = {}
        self.control_stream = {}


    def run(self):
        self.connect_to_server()
        ic(self.connected)
        if self.connected:
            self.running = True

            while self.running:
                if self.krpc_conn.krpc.current_game_scene == self.krpc_conn.krpc.GameScene.flight:
                    if self.vessel is None:
                        self.vessel = self.krpc_conn.space_center.active_vessel
                        self.vessel_info = self.vessel.flight()
                        self.vessel_control = self.vessel.control
                        if not self.stream_added:
                            refframe = self.vessel.orbit.body.reference_frame
                            self.flight_info = self.vessel.flight(refframe)
                        
                        
                    
                        
                            for tele, ref in TELEMETRY.items():
                                match ref:
                                    case "vessel_flight":
                                        self.telemetry_stream[tele] = self.krpc_conn.add_stream(getattr, self.vessel_info,tele)
                                    case "flight":
                                        self.telemetry_stream[tele] = self.krpc_conn.add_stream(getattr,self.flight_info,tele)
                                    case "vessel":
                                        self.telemetry_stream[tele] = self.krpc_conn.add_stream(getattr,self.vessel,tele)
                                    case "pid":
                                        self.telemetry_stream[tele] = self.krpc_conn.add_stream(self.vessel.angular_velocity,self.vessel.surface_reference_frame)
                                    
                        
                            for contr in CONTROL:
                                self.control_stream[contr] = self.krpc_conn.add_stream(getattr, self.vessel_control, contr)
                            self.stream_added = True
                        #self.telemetry_stream["speed"] = self.krpc_conn.add_stream(getattr,self.flight_info,"speed")
                        #self.telemetry_stream["aerodynamic_force"] = self.krpc_conn.add_stream(getattr,self.flight_info,"aerodynamic_force")
                    telemetry_dict = {}
                    for tele in TELEMETRY:
                        try:
                            telemetry_dict[tele] = self.telemetry_stream[tele]()
                        except Exception as e:
                            ic("skiped",tele)
                    control_dict = {}
                    for contr in CONTROL:
                        try:
                            telemetry_dict[contr] = self.control_stream[contr]()
                        except Exception as e:
                            ic('skipped', contr)
                    #for tele in VESSEL_TELEMETRY:
                        #try:
                            #telemetry_dict[tele] = self.telemetry_stream[tele](refframe)
                        #except Exception as e:
                            #ic("skiped",tele)
                    self.telemetry_updated.emit(telemetry_dict, control_dict)
                    self.msleep(10)
                    
                else:
                    self.msleep(100)

        return
    
    def check_vessel(self):

        return
    
    def connect_to_server(self):
        self.krpc_conn = krpc.connect()
        if self.krpc_conn.krpc.get_status():
            
            self.connected = True
            
        else:
            self.connected = False
        return
        




class EthReader(QtCore.QThread):
    data_received = pyqtSignal(int)
    def __init__(self,host="192.168.1.10", port=50000, parent = None):
        super().__init__(parent)
        self.host = host
        self.port = port
        self.connected = False
        self.running=False
        self.paused = False
        self.sock = None
        self.queue = Queue(maxsize=1000)
        self.total_received = 0


    def getStatus(self):
        return self.running
    
    def pause(self):
        self.paused = True

    def resume(self):
        self.paused = False

    def connect_socket(self):
        """Try to connect with 1s timeout; return True on success"""
        try:
            self.sock = socket.create_connection((self.host, self.port), timeout=1)
            self.sock.settimeout(0.5)
            self.connected = True
            #self.status_changed.emit("connected")
            print(f"Connected to {self.host}:{self.port}")
            return True
        except Exception as e:
            #self.status_changed.emit(f"connect_failed: {e}")
            self.connected = False
            print(f"TCP connection failed: {e}")
            return False

    def run(self):

        self.running = True
        buffer = ""
        if not self.connect_socket():
            self.running = False
            return

        while self.running:
            if self.paused:
                self.msleep(100)
                continue

            try:
                data = self.sock.recv(2048)
                if not data:
                    raise ConnectionError("Connection closed by server")
                buffer += data.decode(errors="ignore")
                while '\r\n' in buffer:
                    line, buffer = buffer.split('\r\n', 1)
                    count = line.strip()
                    if line:
                        try:
                            value = int(count)
                            raw16 = value & 0xFFFF           # keep lower 16 bits
                            code12 = raw16 >> 4               # top 12 bits
                            v_xadc = (code12 / 4095.0)*3.3
                            #self.data_received.emit(value)
                            try:
                                self.queue.put_nowait(v_xadc)
                                self.total_received += 1
                            except:
                                pass
                        except ValueError:
                            print(f"Invalid number received: {count}")
                
            except Exception as e:
                            print(f"Parse error: {e} line was {count}")
            except socket.timeout:
                print("socket timeout")
                self.sock = socket.create_connection((self.host, self.port), timeout=1)
                continue
            except Exception as e:
                print(f"Socket error: {e}")
                self.running = False
                break

        if self.sock:
            self.sock.close()

    def stop(self):
        self.running = False
        try:
            if self.sock:
                self.sock.close()
            self.wait()
        except:
            pass

class EthSender(QtCore.QThread):
    command_send = pyqtSignal(dict)
    def __init__(self,host="192.168.1.10", port=50001, parent = None):
        super().__init__(parent)
        self.host = host
        self.port = port
        self.connected = False
        self.sock = None
        self.running = False
        self._pending_command = None       # last-wins value from spinner
        self._lock = QtCore.QMutex()
        

    def connect_socket(self):
        try:
            self.sock = socket.create_connection((self.host, self.port), timeout=1)
            self.sock.settimeout(0.5)
            self.connected = True
            print(f"Connected to {self.host}:{self.port}")
            return True
        except Exception as e:
            print(f"Connection failed : {e}")
            return False
    
    def set_command(self, command: dict):
        # last-wins: just store it; the thread will send the latest
        with QtCore.QMutexLocker(self._lock):
            self._pending_coeff = command
    
        
    def send_command(self,command:dict):
        json_data = json.dumps(command) + "\n" # Convert dict to JSON string
        self.sock.sendall(json_data.encode())  # Send the JSON string
        print(f"command sent {command}")
        return
    
    def run(self):
        
        self.running = True
        # initial connect (retry until connected or stop)
        while self.running and not self.connect_socket():
            self.msleep(1000)

        while self.running:
            # check pending coeff and send if any
            command_to_send = None
            with QtCore.QMutexLocker(self._lock):
                if self._pending_command is not None:
                    command_to_send = self._pending_command
                    self._pending_command = None

            if command_to_send is not None:
                ok = self.send_command(command_to_send)
                if not ok:
                    # try reconnect once
                    if self.sock:
                        try: self.sock.close()
                        except: pass
                        self.sock = None
                    if not self.connect():
                        self.msleep(1000)  # wait then try again later
                    else:
                        # retry once after reconnect
                        self.send_command(command_to_send)

            # small sleep to avoid busy loop; 10–20 ms is fine
            self.msleep(20)

        # cleanup
        try:
            if self.sock:
                self.sock.close()
        except:
            pass
        self.sock = None
