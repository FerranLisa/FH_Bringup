# 2026-10-01T11:38:36.156057
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

comp = client.get_component(name="FH_Carrier_Test")
comp.build()

vitis.dispose()

vitis.dispose()

