
import krpc
import time
conn = krpc.connect(name='Hello World')
vessel = conn.space_center.active_vessel
print(f"Vessel {vessel.name}")
flight_info = vessel.flight()
print(f"Altitude {flight_info.mean_altitude}")
refframe = vessel.orbit.body.reference_frame
control = vessel.control
ap = vessel.auto_pilot

print(f"... set throttle and pointy nose up flamy nose down")
control.throttle = 1.0
ap.target_pitch_and_heading(90, 90)  # 90° pitch = straight up, 90° heading = east
ap.engage()

mean_altitude = conn.get_call(getattr, flight_info, 'mean_altitude')



# Create an event from the expression


print(f"Lift off")
control.activate_next_stage()
time.sleep(0.5)
control.activate_next_stage()

flight_plan = {
    1000:80,
    3000:70,
    5000:55,
    10000:45,
    20000:35,
    45000:20,
    60000:10,
    80000:0
}

for alt, pitch in flight_plan.items():

    expr = conn.krpc.Expression.greater_than(
    conn.krpc.Expression.call(mean_altitude),
    conn.krpc.Expression.constant_double(alt))

    event = conn.krpc.add_event(expr)

    with event.condition:
        event.wait()
        print(f'Altitude reached {alt}m set {pitch, 90}')
        ap.target_pitch_and_heading(pitch, 90)

    




