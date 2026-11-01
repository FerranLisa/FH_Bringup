# 2026-11-01T12:07:34.913592500
import vitis

client = vitis.create_client()
client.set_workspace(path="software")

comp = client.get_component(name="FH_Carrier_Test")
comp.build()

