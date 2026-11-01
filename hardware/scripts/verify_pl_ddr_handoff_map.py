from pathlib import Path
import json,sys
r=Path(__file__).resolve().parents[1]
d=json.loads((r/'FH_Carrier_Bringup.srcs/sources_1/bd/design_1/design_1.bd').read_text())['design']['addressing']
active=[]
for master,m in d.items():
    for space,s in m['address_spaces'].items():
        for v in s['segments'].values():
            if v.get('is_excluded')!='TRUE':
                active.append([master,space,v['address_block'],int(v['offset'],16),v['range']])
active.sort()
p=r/'audit/pl_ddr4/routed_assigned_addresses.json'
if '--snapshot' in sys.argv:
    assert not p.exists(), 'Do not overwrite the routed design address baseline'
    p.write_text(json.dumps(active,indent=2)+'\n')
else:
    baseline=json.loads(p.read_text())
    if '/gmax_dual_ring' not in d:
        assert baseline==active, 'Handoff differs from routed V24 baseline'
    else:
        extra=[]
        for master,space in [('/zynq_ultra_ps_e_0','Data'),('/gmax_dual_ring','m_axi')]:
            regs=[('gmax3412_emulator_1/s_axi/reg0',0xA0080000),
                  ('gmax_capture_ctrl_b/S_AXI/Reg',0xA0090000),
                  ('gmax_capture_dma_b/S_AXI_LITE/Reg',0xA00A0000)]
            if master.startswith('/zynq'):
                regs.append(('gmax_dual_ring_ctrl/S_AXI/Reg',0xA00B0000))
            else:
                regs += [('gmax3412_emulator_0/s_axi/reg0',0xA0030000),
                         ('gmax_capture_ctrl/S_AXI/Reg',0xA0040000),
                         ('gmax_capture_dma/S_AXI_LITE/Reg',0xA0050000)]
            extra += [[master,space,'/'+seg,base,'64K'] for seg,base in regs]
        extra.append(['/gmax_capture_dma_b','Data_S2MM',
                      '/pl_ddr4/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK',0x1000000000,'4G'])
        assert sorted(baseline+extra)==active, 'Unexpected V25 reachability or changed V24 address'
    print('PL_DDR_HANDOFF_MAP_PASS: V24 addresses preserved; exact V25 extensions verified when present')
