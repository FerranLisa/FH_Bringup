# 2026-09-24T13:07:38.991536700
import vitis

client = vitis.create_client()
client.set_workspace(path="FH_Carrier_Bringup")

comp = client.get_component(name="FH_Carrier_IBERT_FSBL")
comp.build()

status = comp.clean()

comp.build()

comp = client.get_component(name="FH_Carrier_Test")
status = comp.clean()

comp.build()

comp.build()

status = comp.clean()

comp.build()

status = comp.clean()

comp.build()

comp.build()

client.delete_component(name="FH_Carrier_IBERT_FSBL")

vitis.dispose()

