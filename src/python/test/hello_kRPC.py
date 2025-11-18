import krpc
conn = krpc.connect(name='Hello World')
vessel = conn.space_center.active_vessel
print(f"Vessel {vessel.name}")
flight_info = vessel.flight()
print(f"Altitude {flight_info.mean_altitude}")
refframe = vessel.orbit.body.reference_frame

mean_altitude = conn.get_call(getattr, flight_info, 'mean_altitude')

# Create an expression on the server
expr = conn.krpc.Expression.greater_than(
    conn.krpc.Expression.call(mean_altitude),
    conn.krpc.Expression.constant_double(1000))

# Create an event from the expression
event = conn.krpc.add_event(expr)

# Wait on the event
with event.condition:
    event.wait()
    vessel.
    print('Altitude reached 1000m')

    ap = vessel.auto_pilot

# 2) Setup before launch
control.throttle = 1.0
ap.target_pitch_and_heading(90, 90)  # 90° pitch = straight up, 90° heading = east
ap.engage()

print("Launching...")
control.activate_next_stage()  # decouple + ignite (depends on your staging)

# 3) Climb straight up until 1000 m
while True:
    alt = flight.mean_altitude
    print(f"Altitude: {alt:.1f} m")
    if alt >= 1000:
        break
    time.sleep(0.1)  # don't hammer the CPU

# 4) At 1000 m, change direction (start turning)
print("1000 m reached, starting gravity turn...")
ap.target_pitch_and_heading(80, 90)  # tilt to 80° pitch, still heading east
# you can also slowly decrease pitch with altitude in a bigger script