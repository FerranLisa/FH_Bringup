# 2026-10-01T13:30:32.985033400
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

comp = client.get_component(name="FH_Carrier_Test")
comp.build()

status = comp.clean()

comp.build()

vitis.dispose()

